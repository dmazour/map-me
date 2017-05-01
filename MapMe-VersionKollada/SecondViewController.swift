//
//  SecondViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/10/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI

class SecondViewController: UIViewController {
    
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var tabBarButton: UITabBarItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        friendsTableView.dataSource = self
        FriendSystem.system.addFriendObserver {
            self.friendsTableView.reloadData()
        }
        FriendSystem.system.addRequestObserver {
//            print(FriendSystem.system.requestList)
        }
        
    }
    
    @IBAction func addFriendsPressed(_ sender: Any) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension SecondViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FriendSystem.system.friendList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create cell
        var cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? UserCell
        if cell == nil {
            tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
            cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? UserCell
        }
        
        // Modify cell
        cell!.button.setTitle("Remove", for: UIControlState())
        cell!.emailLabel.text = FriendSystem.system.friendList[indexPath.row].email
        
        cell!.setFunction {
            let id = FriendSystem.system.friendList[indexPath.row].id
            FriendSystem.system.removeFriend(id!)
        }
        
        // Return cell
        return cell!
    }
    
}

