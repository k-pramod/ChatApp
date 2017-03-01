//
//  ViewController.swift
//  ChatApp
//
//  Created by Brian Wang on 2/25/17.
//  Copyright © 2017 GT iOS Club. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class ViewController: UIViewController {

    // first reference to the root of your database
    var root:FIRDatabaseReference!
    
    // backing container for all of the messages from Firebase
    var messages:[Message] = []
    
    // iboutlets
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tableView delegates
        tableView.delegate = self
        tableView.dataSource = self
        
        // set the root to the proper reference
        root = FIRDatabase.database().reference()
        
        //load messages
        observeMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /*
     observeMessages() sets up the observation, which gets called every time a new message is added to firebase.
     */
    func observeMessages() {
        // "/messages" reference in firebase
        let messagesRef = root.child("messages")
        
        /*
         create a notification observation for whenever a child is added (.childAdded).
         Every time that a child is added to messages, call this function for that child.
         The difference between event type .childAdded and event type .value:
              childAdded: snapshot is based on "/messages/{childID}"
              value:      snapshot is based on "/messages"
         */
        messagesRef.observe(.childAdded, with: { snapshot in
            
            //if the snapshot.value exists and can be casted as a [String: Any], set it to non-optional-type `value`, then check if you can get the text and date and cast them to non-optional String and TimeInterval. If so, then execute the block inside
            if let value = snapshot.value as? [String: Any],
                let text = value["text"] as? String,
                let timeInterval = value["date"] as? TimeInterval {
                
                // convert timeinterval back to Date object
                let date = Date(timeIntervalSince1970: timeInterval)
                
                // create message object
                let message = Message(text: text, date: date)
                
                // append message to backing array
                self.messages.append(message)
                
                // refresh the tableview UI
                self.tableView.reloadData()
                
                //get bottom index and scroll to the bottom of the screen.
                let bottomIndex = IndexPath(row: self.messages.count - 1, section: 0)
                self.tableView.scrollToRow(at: bottomIndex, at: .bottom, animated: true)
            }
        })
        
    }
    
    
    /*
     send() is called whenever the Send button is pressed
     creates a new message object under "/messages
     Hiearchy looks like so:
     root (/):
        messages:
            {childAutoID}:
                text: "Hello World"
                date: 1488167921.291031
            {childAutoID}:
                text: "Dank Memes"
                date: 420420420.420420420
            {childAutoID}:
                text: "Love me some pie"
                date: 3141592.65359
            ...
     
     */
    @IBAction func send() {
        // "/messages/{childAutoID}" reference in firebase
        let childRef = root.child("messages").childByAutoId()
        
        // data for the {childAutoID} object
        //      `text` is from the messageTextField
        //      `date` is the current date, which is converted into a timeinterval representation.
        let data:[String : Any] = [
            "text": messageTextField.text ?? "nil message",
            "date": Date().timeIntervalSince1970
        ]
        
        //add the data (wow so easy)
        childRef.setValue(data)
        
        //clear the message
        messageTextField.text = ""
    }

}

/*
 This extension is a container for the UITableViewDelegate and UITableViewDataSource delegate methods.
 You don't have to have an extension for these functions. I mean you could just put all the delegate methods in the ViewController class (above), but this its a nice way to separate your code.
 */
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    // returns the number of table entries, which is represented by the array of messages
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    // returns the tableview cell for a particular indexpath (section, row)
    // this gets called for every indexpath
    // since we have only 1 section (default), this gets called messages.count times
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //borrow a copy of the cell from the tableView
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        
        //get the message at array given the index
        let message = messages[indexPath.row]
        
        // set the pre-made textlabels to the message and date for the message
        cell.textLabel?.text = message.text
        cell.detailTextLabel?.text = message.date.formattedString()

        // finally return the cell back to the view
        return cell
    }
    
}

/*
 Message is the container for the Message Entity that we pass between this app and Firebase
 Since it is a struct and not a class, it has a synthesized constructor for text and date (so you don't have to write your own constructor)
 */
struct Message {
    var text:String
    var date:Date = Date()
}

/*
 This extension adds a function to all Date objects, which converts any date object to a formatted string representation of the date.
 */
extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd yyyy, h:mm a"
        
        // "self" is the date object you're calling the formatter on
        return formatter.string(from: self)
    }
}
