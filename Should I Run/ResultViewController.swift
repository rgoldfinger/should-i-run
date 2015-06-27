//
//  ResultViewController.swift
//  Should I Run
//
//  Created by Roger Goldfinger on 7/17/14.
//  Copyright (c) 2014 Should I Run. All rights reserved.
//

import UIKit

class ResultViewController: UITableViewController, DataHandlerDelegate {
    
    var results = [Route]()
    var currentBestRoute:Route?
    var currentSecondRoute:Route?
    
    var currentSeconds = 0
    var currentMinutes = 0
    var followingCurrentMinutes:Int? = 0
    
    //alarm
    var alarmTime = 0
    
    //result area things
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet weak var alarmButton: UIButton!
    
    //cell 1
    var destinationLabelText: String = ""
    var timeToNextTrainLabelText: String = ""
    var secondsToNextTrainLabelText: String = ""
    
    //cell 2
    var distanceToStationLabelText: String = ""
    var stationNameLabelText: String = ""
    
    //cell 3
    var minutesWalkingLabelText: String = ""
    
    //cell 4
    var minutesRunningLabelText: String = ""
    
    //cell 5 
    var followingDepartureLabelText: String = ""
    var followingDepartureDestinationLabelText: String = ""
    var followingDepartureSecondsLabelText: String = ""
    
    var secondTimer: NSTimer = NSTimer()
    var updateResultTimer : NSTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = globalBackgroundColor
        self.instructionLabel!.hidden = true
        self.alarmButton!.hidden = true
        self.edgesForExtendedLayout = UIRectEdge() // so that the views are the same distance from the navbar in both ios 7 and 8
        self.extendedLayoutIncludesOpaqueBars = true
        DataHandler.instance.delegate = self
        
        self.displayResults()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.updateResultTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: Selector("updateWalkingDistance:"), userInfo: nil, repeats: true)
        self.secondTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateTimes:"), userInfo: nil, repeats: true)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        self.updateResultTimer.invalidate()
        self.secondTimer.invalidate()
    }
    
    func handleDataSuccess() {
        self.displayResults()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView?) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //TODO: if there's no second departure, return 3
        return 4
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let rowNum = indexPath.row
        switch rowNum {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell1") as! Cell1ViewController
            cell.update(self.destinationLabelText,
                timeToNextTrainLabelText: self.timeToNextTrainLabelText,
                secondsToNextTrainLabelText: self.secondsToNextTrainLabelText)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell2") as! Cell2ViewController
            cell.update(self.distanceToStationLabelText, stationNameLabelText: self.stationNameLabelText)
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell3") as! Cell3ViewController
            cell.update(self.minutesWalkingLabelText)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell4") as! Cell4ViewController
            cell.update(self.minutesRunningLabelText)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func displayResults() {
        self.results = DataHandler.instance.getResults()
        if (self.results.count > 0) {
            let firstRoute = self.results[0]
            self.currentBestRoute = firstRoute
            let departingIn: Int = Int(firstRoute.departureTime! - NSDate.timeIntervalSinceReferenceDate()) / 60
            self.currentMinutes = departingIn
            self.currentSeconds = Int(firstRoute.departureTime! - NSDate.timeIntervalSinceReferenceDate()) % 60
        } else {
            self.handleError("sorry, couldn't find any routes")
            self.updateResultTimer.invalidate()
            self.secondTimer.invalidate()
            return
        }
        
        if (self.results.count > 1) {
            let secondRoute = self.results[1]
            self.currentSecondRoute = secondRoute
            self.followingCurrentMinutes = Int(secondRoute.departureTime! - NSDate.timeIntervalSinceReferenceDate()) / 60
        }
        
        //------------------result area things
        // run or not?
        if currentBestRoute!.shouldRun {
            self.instructionLabel.hidden = false
            let runUIColor = colorize(0xFC5B3F)
            self.instructionLabel.textColor = runUIColor
            
            self.instructionLabel.text = "Run!"
            self.instructionLabel.font = UIFont(descriptor: UIFontDescriptor(name: "Helvetica Neue Light Italic", size: 50), size: 50)
            self.alarmButton.hidden = true
        } else {
            self.instructionLabel.hidden = false
            self.instructionLabel.text = "Nah, take it easy"
            self.instructionLabel.font = UIFont(descriptor: UIFontDescriptor(name: "Helvetica Neue Thin Italic", size: 30), size: 30)
            
            let walkUIColor = colorize(0x6FD57F)
            
            self.instructionLabel.textColor = walkUIColor
            
            self.alarmButton.hidden = false
            self.alarmTime = self.currentMinutes - self.currentBestRoute!.walkingTime
        }
        
        //------------------detail area things
        
        //distance to station label
        self.distanceToStationLabelText = String(self.currentBestRoute!.distanceToStation!)
    
        //line and destination station label, departure station label
        if self.currentBestRoute!.agency == "bart" {
            
            let destinationStation = self.currentBestRoute!.eolStationName
            self.destinationLabelText = "towards \(destinationStation)"
            
            self.stationNameLabelText = "meters to \(self.currentBestRoute!.originStationName) station"

            
        } else if self.currentBestRoute!.agency == "muni" {
            self.destinationLabelText = "\(self.currentBestRoute!.lineName) / \(self.currentBestRoute!.eolStationName)"
            self.stationNameLabelText = "meters to \(self.currentBestRoute!.originStationName)"
            
        } else if self.currentBestRoute!.agency == "caltrain" {
            self.destinationLabelText = "\(self.currentBestRoute!.lineName) towards \(self.currentBestRoute!.eolStationName)"
            self.stationNameLabelText = "meters to \(self.currentBestRoute!.originStationName)"
        }
        
        //------------------running and walking time labels
        self.minutesRunningLabelText = String(self.currentBestRoute!.runningTime)
        self.minutesWalkingLabelText = String(self.currentBestRoute!.walkingTime)
        
        //timer Labels
        self.updateTimes(nil)

        //following destination station name label
        if let following:Route = self.currentSecondRoute {
            if following.agency == "bart" {
                self.followingDepartureDestinationLabelText = "towards \(following.eolStationName)"
            } else if following.agency == "muni" {
                self.followingDepartureDestinationLabelText = "\(following.lineName) / \(following.eolStationName)"
            }
        } else {
            self.followingDepartureDestinationLabelText = "No other departures found"
            self.followingDepartureSecondsLabelText = ""
            self.followingDepartureLabelText = ""
        }
    }
    
    func updateWalkingDistance(timer: NSTimer?){
        DataHandler.instance.updateWalkingDistances()

    }
    
    func updateTimes(timer: NSTimer?) {

        if self.currentBestRoute != nil {
            self.currentMinutes = Int(self.currentBestRoute!.departureTime! - NSDate.timeIntervalSinceReferenceDate()) / 60
            
            // check that we haven't run out of time
            // if so, segue back
            if self.currentMinutes < -1 {
                self.returnToRoot(nil)
                self.updateResultTimer.invalidate()
                self.secondTimer.invalidate()
                return
            }
            
            self.currentSeconds = Int(self.currentBestRoute!.departureTime! - NSDate.timeIntervalSinceReferenceDate()) % 60
            
            if self.currentSecondRoute != nil {
                self.followingCurrentMinutes = Int(self.currentSecondRoute!.departureTime! - NSDate.timeIntervalSinceReferenceDate()) / 60
                self.followingDepartureLabelText = String(self.followingCurrentMinutes!)
            }

            self.timeToNextTrainLabelText = String(currentMinutes)
            
            if self.currentSeconds < 10 {
                self.secondsToNextTrainLabelText = ":0" + String(currentSeconds)
                self.followingDepartureSecondsLabelText = ":0" + String(currentSeconds)
            } else {
                self.secondsToNextTrainLabelText = ":" + String(currentSeconds)
                self.followingDepartureSecondsLabelText = ":" + String(currentSeconds)
            }
        }
    }
    
    // Segues and unwinds-----------------------------------------------------
    
    @IBAction func returnToRoot(sender: UIButton?) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {

        if segue.identifier == "AlarmSegue" {
            let dest: AddAlarmViewController = segue.destinationViewController as! AddAlarmViewController
            dest.walkTime = self.alarmTime
        }
    }
    
    // Error handling-----------------------------------------------------
    
    // This function gets called when the user clicks on the alertView button to dismiss it (see didReceiveGoogleResults)
    // It performs the unwind segue when done.
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        self.returnToRoot(nil)
    }
    
    func handleError(errorMessage: String) {
        // Create and show error message
        // delegates to the alertView function above when 'Ok' is clicked and then perform unwind segue to previous screen.
        let message: UIAlertView = UIAlertView(title: "Oops!", message: errorMessage, delegate: self, cancelButtonTitle: "Ok")
        message.show()
    }
}

