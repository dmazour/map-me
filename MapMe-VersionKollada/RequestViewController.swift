//
//  RequestViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/23/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import Foundation
import UIKit

class RequestViewController: UIViewController {
    
    
    @IBOutlet weak var requestTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Friend Requests"
        requestTableView.dataSource = self
        FriendSystem.system.addRequestObserver {
            print(FriendSystem.system.requestList)
            self.requestTableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToFriends" {
            let nextScene =  segue.destination as! SecondViewController
            nextScene.tabBarItem.isEnabled = true
        }
    }
}

extension RequestViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FriendSystem.system.requestList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create cell
        var cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? UserCell
        if cell == nil {
            tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
            cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? UserCell
        }
        
        // Modify cell
        cell!.button.setTitle("Accept", for: UIControlState())
        cell!.emailLabel.text = FriendSystem.system.requestList[indexPath.row].email
        
        cell!.setFunction {
            let id = FriendSystem.system.requestList[indexPath.row].id
            FriendSystem.system.acceptFriendRequest(id!)
        }
        
        // Return cell
        return cell!
    }
    
}
