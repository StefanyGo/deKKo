//
//  CameraListTableViewCell.swift
//  deKKo
//
//  Created by Arthur on 2017/4/13.
//  Copyright © 2017年 ArcCotagent. All rights reserved.
//

import UIKit
import TwilioVideo
import Parse
import Notie
class CameraListTableViewCell: UITableViewCell
{
    
    
    // Configure access token manually for testing, if desired! Create one manually in the console
    // at https://www.twilio.com/user/account/video/dev-tools/testing-tools
    var accessToken = "TWILIO_ACCESS_TOKEN"
    var userName = ""
    // Configure remote URL to fetch token from
    var tokenUrl = "http://dekkotest.x10host.com/?name=\(String.random())"
    
    
    
    // Video SDK components
    
    var localMedia: TVILocalMedia?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var participant: TVIParticipant?
    var room: TVIRoom?
    
    
    var connectOptions: TVIConnectOptions?
    
    
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var viewsCount: UILabel!
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        
        
        if (accessToken == "TWILIO_ACCESS_TOKEN")
        {
            do
            {
                tokenUrl =  tokenUrl.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
                accessToken = try TokenUtils.fetchToken(url: tokenUrl)
                
                
            }
            catch
            {
                let message = "Failed to fetch access token"
                logMessage(messageText: message)
                
            }
        }
//        let tapToMessage = UITapGestureRecognizer(target: self, action: #selector(self.showNotie(sender:)))
//        tapToMessage.numberOfTapsRequired=2
//        self.cameraView.addGestureRecognizer(tapToMessage)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        self.showNotie(sender: AnyObject.self as AnyObject)
        // Configure the view for the selected state
    }
    
    func logMessage(messageText:String)
    {
        print(messageText)
    }
    func connect()
    {
        self.room = TVIVideoClient.connect(with: self.connectOptions!, delegate: self)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(CameraListTableViewCell.onTimer), userInfo: nil, repeats: true)
    }
    func disconnect()
    {
        self.room?.disconnect()
    }
    func onTimer()
    {
        //Query the table ROOMINFO
        let query = PFQuery(className: "ROOMINFO")
        //Sort the table by roomName
        query.order(byDescending: "roomName")
        query.whereKey("roomName", contains: room?.name)
        //Grab only 20 Orders
        query.limit = 20
        
        //Start Grabing
        query.findObjectsInBackground { (roomInfos: [PFObject]?, error: Error?) -> Void in
            if let roomInfos = roomInfos
            {
                //Save it to roomInfos[]
                print(roomInfos)
                
                if let participants = roomInfos[0]["participants"] as? Int
                {
                    self.viewsCount.text = "\(participants) views"
                }
            }
            else
            {
                print(error?.localizedDescription)
                // handle error
            }
        }

    }
    
    
    func showNotie(sender: AnyObject)
    {
        let notie = Notie(view: self.cameraView, message: "Do you want to purchase this object?", style: .Confirm)
        //notie.leftButtonBackgroundColor = UIColor(hue: 0.2694, saturation: 1, brightness: 0.79, alpha: 1.0)
        
        
        
        notie.leftButtonAction = {
            notie.dismiss()
        }
      //  notie.leftButtonBackgroundColor
        
        notie.rightButtonAction = {
            
            notie.dismiss()
        }
        
        notie.show()
    }
    
    func showInputNotie(sender: AnyObject)
    {
        let notie = Notie(view: self.cameraView, message: "Please enter your email address", style: .Input)
        notie.placeholder = "email@example.com"
        notie.buttonCount = Notie.buttons.standard
        notie.leftButtonAction = {
            print(notie.getText())
            notie.dismiss()
        }
        
        notie.rightButtonAction = {
            notie.dismiss()
        }
        
        notie.show()
    }

        
}
extension CameraListTableViewCell : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        
        // At the moment, this example only supports rendering one Participant at a time.
        
        logMessage(messageText: "Connected to room \(room.name) as \(room.localParticipant?.identity)")
        
        if (room.participants.count > 0) {
            self.participant = room.participants[0]
            self.participant?.delegate = self
        }
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        logMessage(messageText: "Disconncted from room \(room.name), error = \(error)")
        
        //self.cleanupRemoteParticipant()
        self.room = nil
        
        //self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        logMessage(messageText: "Failed to connect to room with error")
        self.room = nil
        
        //self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIParticipant) {
        if (self.participant == nil) {
            self.participant = participant
            self.participant?.delegate = self
        }
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) connected")
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIParticipant) {
        if (self.participant == participant) {
            //cleanupRemoteParticipant()
            self.viewsCount.text = ""
        }
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
    }
}

// MARK: TVIParticipantDelegate
extension CameraListTableViewCell : TVIParticipantDelegate {
    func participant(_ participant: TVIParticipant, addedVideoTrack videoTrack: TVIVideoTrack) {
        logMessage(messageText: "Participant \(participant.identity) added video track")
        
        if (self.participant == participant)
        {
            
            
            
            let renderer = TVIVideoViewRenderer.init()
            videoTrack.addRenderer(renderer)
            renderer.view.frame = self.cameraView.bounds
            renderer.view.contentMode = .scaleAspectFill
            self.cameraView.addSubview(renderer.view)

          //  videoTrack.attach(self.cameraView)
            
            self.cameraView.bringSubview(toFront: self.viewsCount);
        }
    }
    
    func participant(_ participant: TVIParticipant, removedVideoTrack videoTrack: TVIVideoTrack) {
        logMessage(messageText: "Participant \(participant.identity) removed video track")
        
        if (self.participant == participant) {
            videoTrack.detach(self.cameraView)
            
        }
    }
    
    func participant(_ participant: TVIParticipant, addedAudioTrack audioTrack: TVIAudioTrack) {
        logMessage(messageText: "Participant \(participant.identity) added audio track")
        
    }
    
    func participant(_ participant: TVIParticipant, removedAudioTrack audioTrack: TVIAudioTrack) {
        logMessage(messageText: "Participant \(participant.identity) removed audio track")
    }
    
    func participant(_ participant: TVIParticipant, enabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        logMessage(messageText: "Participant \(participant.identity) enabled \(type) track")
    }
    
    func participant(_ participant: TVIParticipant, disabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        logMessage(messageText: "Participant \(participant.identity) disabled \(type) track")
    }
    
   }

