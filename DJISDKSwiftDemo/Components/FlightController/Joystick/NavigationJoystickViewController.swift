//
//  JoystickTestViewController.h
//  DJISdkDemo
//
//  Created by DJI on 14-10-27.
//  Copyright (c) 2014 DJI. All rights reserved.
//
import UIKit
import CoreLocation
import DJISDK

class NavigationJoystickViewController: DJIBaseViewController, DJIFlightControllerDelegate, DJISimulatorDelegate , DJIRemoteControllerDelegate, DJICameraDelegate{
    
    var mThrottle: CGFloat = 0.0
    var mPitch: CGFloat = 0.0
    var mRoll: CGFloat = 0.0
    var mYaw: CGFloat = 0.0
    var mState: DJIFlightControllerCurrentState = DJIFlightControllerCurrentState()
    
    var controlling = false
    var yawCount = 0
    var idIndex = 0
    
    // TODO: Why need strong here?
    @IBOutlet weak var joystickLeft: JoyStickView!
    @IBOutlet weak var joystickRight: JoyStickView!
    @IBOutlet weak var coordinateSys: UIButton!
    @IBOutlet weak var enableVirtualStickButton: UIButton!
    @IBOutlet weak var simulatorStateLabel: UILabel!
    
    @IBOutlet weak var yawCountLabel: UILabel!
    
    @IBOutlet weak var JSONData: UILabel!
    
    @IBOutlet weak var cameraSystemStateLabel: UILabel!
 
    
    weak var aircraft: DJIAircraft? = nil
    var serverUrl: String? = nil
    

    @IBOutlet weak var sendImageButton: UIButton!
    
    
    var imageMedia: DJIMedia? = nil
    
    var mediaList: [DJIMedia]? {
        
        didSet{
            // Cache the first JPEG media file in the list.
            if (mediaList == nil)
            {
                return
            }
            
            for media:DJIMedia in mediaList! {
                if media.mediaType == DJIMediaType.JPEG {
                    self.imageMedia = media
                }
            }
            if self.imageMedia == nil {
                self.showAlertResult("There is no image media file in the SD card. ")
            }
            self.sendImageButton.enabled = (self.imageMedia != nil)
        }
    }

    @IBAction func updateURLTextField(sender: UITextField) {
        serverUrl = sender.text
    }
    
    @IBAction func onEnterVirtualStickControlButtonClicked(sender: AnyObject) {
        if (self.aircraft != nil) {
            self.aircraft!.flightController?.enableVirtualStickControlModeWithCompletion({[weak self] (error: NSError?) in
                if error != nil {
                    self?.showAlertResult("Enter Virtual Stick Mode:\(error!.description)")
                } else {
                    self?.showAlertResult("Enter Virtual Stick Mode: Success.")
                }
                })
            self.aircraft!.flightController?.yawControlMode = DJIVirtualStickYawControlMode.AngularVelocity
            self.aircraft!.flightController?.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.Velocity

            self.controlling = true
            self.simulatorStateLabel.text = "Virtual Stick mode"


        }
    }

    @IBAction func onExitVirtualStickControlButtonClicked(sender: AnyObject) {
        
    }
    
    private func exitVirtualStickControl(){
        if (self.aircraft == nil) {
            return
        }
        
        self.aircraft!.flightController?.disableVirtualStickControlModeWithCompletion({ [weak self] (error: NSError?) -> Void in
            if error != nil {
                self?.showAlertResult("Exit Virtual Stick Mode: \(error!.debugDescription)")
                
            }
            else {
                self?.showAlertResult("Exit Virtual Stick Mode: Success.")
                self.self!.simulatorStateLabel.text = "Remote Controller mode"
                self!.controlling = false
                
            }
            })
    }

    @IBAction func onTakeoffButtonClicked(sender: AnyObject) {
        if (self.aircraft == nil) {
            return
        }
        
        self.aircraft!.flightController?.takeoffWithCompletion({[weak self] (error: NSError?) -> Void in
            if error != nil {
                self?.showAlertResult("Takeoff: \(error!.description)")
            }
            else {
                self?.showAlertResult("Takeoff: Success.")
            }
        })
    }

    @IBAction func onCoordinateSysButtonClicked(sender: AnyObject) {
        
        if (self.aircraft == nil) {
            return
        }
        
//        self.yawCount = (self.yawCount + 1) % 8
        
        idIndex = (idIndex + 1)%100
        updateOrientation()
        
        //        if self.aircraft!.flightController?.rollPitchCoordinateSystem == DJIVirtualStickFlightCoordinateSystem.Ground {
        //            self.aircraft!.flightController?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.Body
        //            coordinateSys.setTitle("CoordinateSys:Body", forState: .Normal)
        //        }
        //        else {
        //            self.aircraft!.flightController?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.Ground
        //            coordinateSys.setTitle("CoordinateSys:Ground", forState: .Normal)
        //        }
    }
    
    @IBAction func onSimulatorButtonClicked(sender:UIButton) {
        let fc  = self.aircraft?.flightController
        if (fc != nil && fc!.simulator != nil) {
            if (fc!.simulator!.isSimulatorStarted == false ) {
                // The initial aircraft's position in the simulator.
                let location = CLLocationCoordinate2DMake(22, 113)
                fc!.simulator!.startSimulatorWithLocation(location, updateFrequency: 20, GPSSatellitesNumber: 10, withCompletion: { (error: NSError?) -> Void in
                    
                    self.simulatorStateLabel.hidden = true;

                    if (error != nil) {
                        self.showAlertResult("Start simulator error:\(error!.description)")
                    } else {
                        self.showAlertResult("Start simulator succeeded.");
                    }

                })
            }
        }
    }

    @IBAction func onStopSimulatorButtonClicked(sender: AnyObject) {
        
        let fc  = self.aircraft?.flightController
        if (fc != nil && fc!.simulator != nil) {
            if (fc!.simulator!.isSimulatorStarted == true ) {
                
                fc!.simulator!.stopSimulatorWithCompletion({ (error: NSError?) -> Void in
                  
                    self.simulatorStateLabel.hidden = false;
                    if (error != nil) {
                        self.showAlertResult("Stop simulator error:\(error!.description)")
                    } else {
                        self.showAlertResult("Stop simulator succeeded.");
                    }

                })
            }
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //    playerOrigin = player.frame.origin;
        let notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(NavigationJoystickViewController.onStickChanged(_:)), name: "StickChanged", object: nil)
      
        if (ConnectedProductManager.sharedInstance.fetchAircraft() != nil) {
            self.aircraft = self.fetchAircraft()
        
            if (self.aircraft == nil) {
                return
            }
            
            // To be consistent with UI part, set the coordinate to Ground
            if self.aircraft!.flightController != nil {
                self.aircraft!.flightController!.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.Angle
            }
            
            let rc: DJIRemoteController? = self.fetchRemoteController()
            if rc != nil {
                rc!.delegate = self
            }
            
            let camera: DJICamera? = self.fetchCamera()
            if camera != nil {
                camera?.delegate = self
            }
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // flight controller should be ready
        self.aircraft = self.fetchAircraft()
        
        if (self.aircraft != nil) {
            self.aircraft?.flightController?.delegate = self
            self.aircraft?.flightController?.simulator?.delegate = self
        }
        
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let fc = self.fetchFlightController()
        if ( fc != nil) {
            if fc!.delegate === self {
                fc!.delegate = nil
            }
            if fc!.simulator?.delegate === self {
                fc!.simulator?.delegate = nil
            }
        }
    }

    func onStickChanged(notification: NSNotification) {
        var dict: [NSObject : AnyObject] = notification.userInfo!
        let vdir: NSValue = dict["dir"] as! NSValue
        let dir: CGPoint = vdir.CGPointValue()
        let joystick: JoyStickView? = notification.object as? JoyStickView
        if joystick != nil {
            if joystick == self.joystickLeft {
                self.setThrottle(dir.y, andYaw: dir.x)
            }
            else {
                self.setPitch(dir.y, andRoll: dir.x)
            }
        }
    }

    func setThrottle(y: CGFloat, andYaw x: CGFloat) {
        mThrottle = y * -2
        mYaw = x * 30
        self.updateJoystick()
    }

    func setPitch(y: CGFloat, andRoll x: CGFloat) {
        mPitch = y * 15.0
        mRoll = x * 15.0
        self.updateJoystick()
    }

    func updateJoystick() {
        var ctrlData: DJIVirtualStickFlightControlData = DJIVirtualStickFlightControlData()
        ctrlData.pitch = Float(mPitch)
        ctrlData.roll = Float(mRoll)
        ctrlData.yaw = Float(mYaw)
        ctrlData.verticalThrottle = Float(mThrottle)
        if ((self.aircraft != nil && self.aircraft!.flightController != nil) && (self.aircraft!.flightController!.isVirtualStickControlModeAvailable())) {
            NSLog("mThrottle: %f, mYaw: %f", mThrottle, mYaw)
            self.aircraft!.flightController!.sendVirtualStickFlightControlData(ctrlData, withCompletion: nil)
        }
    }

    func flightController(fc: DJIFlightController, didUpdateSystemState state: DJIFlightControllerCurrentState)
    {
        self.mState = state
        
        if self.controlling{
            
            
            
            let yawAngle = self.mState.attitude.yaw + 180.0
            let yawAngleDifference = yawAngle - Double(self.yawCount)*45.0
            
            if yawAngleDifference < 180.0 && yawAngleDifference > -180.0{
                self.mYaw = CGFloat(-yawAngleDifference)
                
            }else if yawAngleDifference >= 180.0{
                self.mYaw = CGFloat(360.0 - yawAngleDifference)
                
            }else if yawAngleDifference <= -180.0{
                self.mYaw = -CGFloat(360.0 + yawAngleDifference)
            }
            self.updateJoystick()
        }
        
    }
    func remoteController(rc: DJIRemoteController, didUpdateHardwareState state: DJIRCHardwareState){
        
//        if self.JSONData.text == nil{
//            self.JSONData.text = String(state.pauseButton.buttonDown.boolValue)
//        }else{
//            self.JSONData.text = self.JSONData.text! + String(state.pauseButton.buttonDown.boolValue)
//        }
//        
////        state.pauseButton
        if state.pauseButton.buttonDown.boolValue == true{
            
            if self.JSONData.text == nil{
                self.JSONData.text = "pressed"
            }else{
                self.JSONData.text = self.JSONData.text! + "pressed"
            }
            self.exitVirtualStickControl()
        }
    }
    func updateOrientation(){
        let manager = AFHTTPSessionManager()
        manager.requestSerializer = AFJSONRequestSerializer()
//        let params = ["longUrl": "MYURL"]
        
        manager.GET("https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=ed88994bbcb534c7c994f858de1f7d75&tags=sky&format=json&nojsoncallback=1", parameters: nil, success: { (theTask:NSURLSessionDataTask, theObject:AnyObject?) in
            let theJSON = theObject as! NSDictionary
            let thePhotos = theJSON["photos"] as! NSDictionary
            let thePhotoList = thePhotos["photo"] as! NSArray
            let theIdJSON = thePhotoList[self.idIndex] as! NSDictionary
            let theId = Int(theIdJSON["id"]!.description)
            if theId != nil{
                self.yawCount = theId! % 8
                self.yawCountLabel.text = "YawCount:" + String(self.yawCount)
                self.JSONData.text = "ID: " + String(theId!)
            }
            }, failure: nil)
        
        
//        manager.POST("https://www.googleapis.com/urlshortener/v1/url?key=MYKEY", parameters: params, success: {(operation: NSURLSessionDataTask!,responseObject: AnyObject?) in
//            print("JSON" + (responseObject?.description)!)
//                self.yawCount = (self.yawCount + 1) % 8
//            },
//                     
//                     
//            failure: { (operation: NSURLSessionDataTask?,error: NSError) in
//               print("Error while requesting shortened: " + error.localizedDescription)
//                self.yawCount = (self.yawCount - 1) % 8
//
//        })
        
        
    }
    

    @IBAction func onSendImageButtonClicked(sender: UIButton) {
        self.sendImageButton.enabled = false
        
        
        if let camera = self.fetchCamera(){
            camera.setCameraMode(DJICameraMode.ShootPhoto, withCompletion: { (error:NSError?) in
                if error != nil{
                    self.showAlertResult("ERROR: setCameraModeToShootWithCompletion:\(error!.description)")
                }else{
                    camera.startShootPhoto(DJICameraShootPhotoMode.Single, withCompletion: { (error:NSError?) in
                        if error != nil{
                            self.showAlertResult("ERROR: shootOnePhotoWithCompletion:\(error!.description)")
                        }
                    })
                }
            })
        }
        
        
        
        
        
        
//        
//        if self.getCameraMode() != DJICameraMode.ShootPhoto{
//            self.fetchCamera()?.setCameraMode(DJICameraMode.ShootPhoto, withCompletion: { (error:NSError?) in
//                self.shootPhotoAndSendToServer()
//            })
//        }else{
//            self.shootPhotoAndSendToServer()
//        }
        
    }
    
    
    func sendPhotoToServer() {
        let downloadData: NSMutableData = NSMutableData()
        self.imageMedia?.fetchMediaDataWithCompletion({[weak self](data:NSData?, stop:UnsafeMutablePointer<ObjCBool>, error:NSError?) -> Void in
            
            if error != nil {
                self?.showAlertResult("ERROR: fetchMediaDataWithCompletion:\(error!.description)")
                self?.sendImageButton.enabled = true
            }
            else {
                downloadData.appendData(data!)
                if Int64(downloadData.length) == self?.imageMedia?.fileSizeInBytes {
                    dispatch_async(dispatch_get_main_queue(), {() -> Void in
                        if let imageData = UIImage(data: downloadData){
                            //                            self?.sendImageToServer("http://169.231.177.184:5000", imageData: imageData)
                            if let urlFromView = self?.serverUrl{
                                self!.yawCountLabel.text = urlFromView
                                self?.sendImageToServer(urlFromView, imageData: imageData)
                            }else {
                                self?.sendImageToServer("http://169.231.177.184:5000", imageData: imageData)
                            }
                        }
                        self?.sendImageButton.enabled = true
                    })
                }
            }
            self?.sendImageButton.enabled = true
            })
    }
    
    func sendImageToServer(urlFromView: String, imageData: UIImage){
        let url = NSURL(string:urlFromView)
        
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        //define the multipart request type
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        let image_Data = UIImageJPEGRepresentation(imageData, 0.5)
        
        let body = NSMutableData()
        
        let fname = "photo.jpg"
        let mimetype = "image/jpeg"
        
        //define the data post parameter
        
        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        body.appendData("Content-Disposition:form-data; name=\"test\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("hi\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        body.appendData("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: \(mimetype)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(image_Data!)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        body.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        request.HTTPBody = body
        
        
        
        let session = NSURLSession.sharedSession()
        
        
        let task = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print(dataString)
            
        }
        
        task.resume()

    }
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    
    func shootPhotoAndSendToServer() {
        let camera: DJICamera? = self.fetchCamera()
        if camera != nil {
            camera?.startShootPhoto(DJICameraShootPhotoMode.Single, withCompletion: {[weak self](error: NSError?) -> Void in
                if error != nil {
                    self?.showAlertResult("ERROR: startShootPhoto:withCompletion::\(error!.description)")
                }else{
                    camera?.setCameraMode(DJICameraMode.MediaDownload, withCompletion: { [weak self](error:NSError?) in
                        if error != nil {
                            self?.showAlertResult("ERROR: startShootPhoto:withCompletion::\(error!.description)")
                        }else{
                            if camera?.mediaManager != nil {
                                camera!.mediaManager!.fetchMediaListWithCompletion( {[weak self](mediaList:[DJIMedia]?, error: NSError?) -> Void in
                                    
                                    if error != nil {
                                        self?.showAlertResult("ERROR: fetchMediaListWithCompletion:\(error!.description)")
                                    }
                                    else {
                                        self?.mediaList = mediaList
                                        self?.showAlertResult("SUCCESS: The media list is fetched. ")
                                        self?.sendPhotoToServer();
                                    }
                                    })
                            }
                        }
                    })
                }
                })
        }
    }

    func simulator(simulator: DJISimulator, updateSimulatorState state: DJISimulatorState) {
        self.simulatorStateLabel.hidden = false
        self.simulatorStateLabel.text = "Yaw: \(state.yaw)\nX: \(state.positionX) Y: \(state.positionY) Z: \(state.positionZ)"
    }
    
    func camera(camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMedia) {
        if newMedia.mediaType == DJIMediaType.JPEG {
            
            let seconds = 0.5
            let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.JSONData.text = "did generate media"

                camera.setCameraMode(DJICameraMode.MediaDownload, withCompletion: { (error:NSError?) in
                    if error != nil{
                        camera.getCameraModeWithCompletion({ (mode :DJICameraMode, error:NSError?) in
                            if error != nil{
                                self.showAlertResult("ERROR: getCameraModeWithCompletion:\(error!.description)")
                            }
                            else{
                                var text:String? = nil
                                switch mode{
                                case .MediaDownload:  text = "download"
                                case .Playback: text = "playback"
                                case .RecordVideo: text = "record"
                                case .ShootPhoto : text = "shoot"
                                case .Unknown: text = "unknown"
                                }
                                
                                self.yawCountLabel.text = text
                            }
                        })
                        self.showAlertResult("ERROR: setCameraModeToDownloadWithCompletion:\(error!.description)")
                    }else{
                        self.imageMedia = newMedia
                        self.sendPhotoToServer()
                    }
                })
            })
        }
    }

    func camera(camera: DJICamera, didUpdateSystemState systemState: DJICameraSystemState) {
                self.cameraSystemStateLabel.text = "isShootingSinglePhoto:  \(systemState.isShootingSinglePhoto) \n isShootingSinglePhotoInRAWFormat:  \(systemState.isShootingSinglePhotoInRAWFormat) \n isShootingIntervalPhoto:  \(systemState.isShootingIntervalPhoto) \n isShootingBurstPhoto:  \(systemState.isShootingBurstPhoto) \n isRecording:  \(systemState.isRecording) \n isStoringPhoto:  \(systemState.isStoringPhoto) \n isCameraOverHeated:  \(systemState.isCameraOverHeated) \n isCameraError:  \(systemState.isCameraError) \n "
    }

    
//        camera.setCameraMode(DJICameraMode.MediaDownload, withCompletion: { (error:NSError?) in
//            if error != nil{
//                self.showAlertResult("ERROR: setCameraModeWithToDownloadCompletion:\(error!.description)")
//            }else{
//                if camera.mediaManager != nil {
//                    camera.mediaManager!.fetchMediaListWithCompletion( {[weak self](mediaList:[DJIMedia]?, error: NSError?) -> Void in
//
//                        if error != nil {
//                            self?.showAlertResult("ERROR: fetchMediaListWithCompletion:\(error!.description)")
//                        }
//                        else {
//                            self?.mediaList = mediaList
//                            self?.showAlertResult("SUCCESS: The media list is fetched. ")
//                            self?.sendPhotoToServer();
//                        }
//                        })
//                }
//                
//            }
//        })

    
    
}



// Utility methods to show the image
//    func showPhotoWithImage(image: UIImage) {
//        let bkgndView: UIView = UIView(frame: self.view.bounds)
//        bkgndView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
//        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CameraFetchMediaViewController.onImageViewTap(_:)))
//        bkgndView.addGestureRecognizer(tapGesture)
//        var width: CGFloat = image.size.width
//        var height: CGFloat = image.size.height
//        if width > self.view.bounds.size.width * 0.7 {
//            height = height * (self.view.bounds.size.width * 0.7) / width
//            width = self.view.bounds.size.width * 0.7
//        }
//        let imgView: UIImageView = UIImageView(frame: CGRectMake(0, 0, width, height))
//        imgView.image = image
//        imgView.center = bkgndView.center
//        imgView.backgroundColor = UIColor.lightGrayColor()
//        imgView.layer.borderWidth = 2.0
//        imgView.layer.borderColor = UIColor.blueColor().CGColor
//        imgView.layer.cornerRadius = 4.0
//        imgView.layer.masksToBounds = true
//        imgView.contentMode = .ScaleAspectFill
//        bkgndView.addSubview(imgView)
//        self.view!.addSubview(bkgndView)
//    }
//
//    func showPhotoWithData(data: NSData?) {
//        if data != nil {
//            let image: UIImage? = UIImage(data: data!)
//            if image != nil {
//                self.showPhotoWithImage(image!)
//            }
//            else {
//                self.showAlertResult("Image Crashed")
//            }
//        }
//    }
