//
//  UserListViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/23/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class UserListViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchText: String?
    
    var rootRef: FIRDatabaseReference?
    var users: FIRDatabaseReference?
    
    var displayUserList: [User]?
    var hasSearched: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchText = ""
        displayUserList = FriendSystem.system.userList
//        populateData()
        searchBar.delegate = self
        self.title = "Users"
        tableView.dataSource = self
        FriendSystem.system.getCurrentUser { (user) in
        }
        
        rootRef = FIRDatabase.database().reference()
        users = rootRef?.child("users")
        
        FriendSystem.system.addUserObserver { () in
            self.tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchText = searchBar.text!
        hasSearched = true
        populateSearchData()
        tableView.reloadData()
    }
    
    func populateSearchData() {
        displayUserList = []
        if searchText == "" {
            displayUserList = FriendSystem.system.userList
        }
        for user in FriendSystem.system.userList {
            if user.email.contains(searchText!) {
                displayUserList?.append(user)
            }
        }
    }
}

extension UserListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FriendSystem.system.userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create cell
        print("in here?")
        var cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? UserCell
        if cell == nil {
            tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
            cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? UserCell
        }
        
        // Modify cell
        cell!.emailLabel.text = FriendSystem.system.userList[indexPath.row].email
        
        cell!.setFunction {
            let id = FriendSystem.system.userList[indexPath.row].id
            FriendSystem.system.sendRequestToUser(id!)
        }
//        if hasSearched {
//            cell!.emailLabel.text = displayUserList?[indexPath.row].email
//        }
//        else {
//            cell!.emailLabel.text = FriendSystem.system.userList[indexPath.row].email
//        }
//        
//        cell!.setFunction {
//            var id: String!
//            if self.hasSearched {
//                id = self.displayUserList?[indexPath.row].id
//            }
//            else {
//                id = FriendSystem.system.userList[indexPath.row].id
//            }
//            var sendRequest = true
//            for friend in FriendSystem.system.friendList {
//                if id == friend.id {
//                    sendRequest = false
//                }
//                print(0)
//            }
//            if sendRequest {
//                FriendSystem.system.sendRequestToUser(id!)
//                print("request sent")
//            }
//        }
        
        // Return cell
        return cell!
    }
    
}
