//
//  ViewController.swift
//  LearningFirebase
//
//  Created by Kioja Kudumu on 1/12/18.
//  Copyright © 2018 Kioja Kudumu. All rights reserved.
//

import UIKit
import Firebase

class UserVC: UIViewController, UIGestureRecognizerDelegate {
    
    var posts = [Post]()
    var onCellTap: ((_ data: String) -> ())?
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //        label.text = "Hello \(firstLast)" - added in case we want to welcome users in the future. May need to change it to just first name in the displayName though.
        
        //observe data that is passed at reference point/ posts reference
        DatabaseService.shared.REF_BASE.child("users").observe(.value) { (snapshot) in

                guard let uid = Auth.auth().currentUser?.uid else { return }
                DatabaseService.shared.REF_BASE.child("users").child(uid).child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
                    print(snapshot)
                    guard let postsSnapshot = PostsSnapshot(with: snapshot) else { return }
                    print("POSTSNAP:\(postsSnapshot)")
                    self.posts = postsSnapshot.posts
                    print("POSTSNAP.POSTS:\(postsSnapshot)")
                    //sorting posts in the proper order
                    self.posts.sort(by: { $0.date.compare($1.date) == .orderedDescending })
                    self.tableView.reloadData()
                })

            
        }
    }
 
    
    
    @IBAction func onUserLogOutTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            performSegue(withIdentifier: "UserSignOutSegue", sender: nil)
        } catch {
            print(error)
        }
    }
    func createSwitch () -> UISwitch{
        let switchControl = UISwitch(frame: CGRect(x:10, y:10, width:0, height:0))
        switchControl.isOn = false
        
        if UserDefaults.standard.object(forKey: "SwitchState") != nil {
            switchControl.isOn = UserDefaults.standard.bool(forKey: "SwitchState")
        }
        
        switchControl.addTarget(self, action: #selector(switchValueDidChange), for: .valueChanged)
        return switchControl
        
    }
    
    @objc func switchValueDidChange(sender: UISwitch!) {
        print("Switch Value : \(sender.isOn)")
        if sender.isOn == true {
            UserDefaults.standard.set(true, forKey: "SwitchState")
            MessagingService.shared.subscribe(to: .newPosts)
            MessagingService.shared.unsubscribe(from: .freePosts)
        } else if sender.isOn == false {
            UserDefaults.standard.set(false, forKey: "SwitchState")
            MessagingService.shared.unsubscribe(from: .newPosts)
            MessagingService.shared.unsubscribe(from: .freePosts)
        }
        
    }

    @IBAction func onSubscribeTapped() {
        let alert = UIAlertController(title: "Toggle Notifications", message: "Tap the switch to toggle notifications on or off", preferredStyle: .actionSheet)
        
        let doneButton = UIAlertAction(title: "Done", style: .default) { (_) in
            print("Done tapped. View should dismiss")
        }
        
        alert.addAction(doneButton)
        alert.view.addSubview(createSwitch())
        alert.popoverPresentationController?.sourceView = self.view
        
        present(alert, animated: true)
        
    }
     var photoThumbnail: UIImage!
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.RawValue(UIInterfaceOrientation.portrait.rawValue))
        }
        else {
            return UIInterfaceOrientationMask.all
        }
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.unknown
    }
    
    override public var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        else {
            return false
        }
    }
    

    

}




//creating table view
extension UserVC: UITableViewDataSource, UITableViewDelegate {
    

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
            photoThumbnail = cell.postImageView.image
            performSegue(withIdentifier: "ToChartImage", sender: self)
    }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ToChartImage" {
        let destViewController: ChartImageController = segue.destination as! ChartImageController
        destViewController.newImage = photoThumbnail
        shouldPerformSegue(withIdentifier: "ToChartImage", sender: Any?.self)
    }
}
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as! UserTableViewCell
        let uid = Auth.auth().currentUser?.uid
        let post = self.posts[indexPath.row]
        
        DatabaseService.shared.REF_BASE.child("users").child(uid!).child("posts").child(post.postId).child("isPending").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value as! String == "false" {
                cell.backgroundColor = UIColor.white
            } else if snapshot.value as! String == "true" {
                cell.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
            }
            
        })

        
        cell.imageView?.contentMode = .scaleAspectFill
        if let postImageURL = post.imageURL {
            let url = URL(string: postImageURL)
            cell.postImageView.kf.setImage(with: url)
//            cell.postImageView.loadImageUsingCacheWithUrlString(urlString: postImageURL)
            
            ////something different
//            cell.postImageView.image = photoThumbnail
        }

        cell.signalLabel?.text = posts[indexPath.row].signal
        cell.symbolLabel?.text = posts[indexPath.row].pair
        cell.priceLabel?.text = posts[indexPath.row].price
        
        //testing constraints
//        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.estimatedRowHeight = 140
 
        
        return cell
    }
    
 
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let closeAction = UIContextualAction(style: .normal, title: "Close") { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//            let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as! UserTableViewCell
            let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
            UIPasteboard.general.string = cell.priceLabel.text
            
            success(true)
        }
        closeAction.title = "Copy"
        closeAction.backgroundColor = .purple
        
        return UISwipeActionsConfiguration(actions: [closeAction])
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let pending = UITableViewRowAction(style: .normal, title: "Pending") { (action, indexPath) in
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let post = self.posts[indexPath.row]
            
            DatabaseService.shared.REF_BASE.child("users").child(uid).child("posts").child(post.postId).child("isPending").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.value as! String == "false" {
                    DatabaseService.shared.REF_BASE.child("users").child(uid).child("posts").child(post.postId).updateChildValues(["isPending":"true"])
                } else if snapshot.value as! String == "true" {
                    print(snapshot.value as! String)
                    DatabaseService.shared.REF_BASE.child("users").child(uid).child("posts").child(post.postId).updateChildValues(["isPending":"false"])
                }
                
            })
            tableView.reloadData()
        }
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let post = self.posts[indexPath.row]
            DatabaseService.shared.REF_BASE.child("users").child(uid).child("posts").child(post.postId).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print("ERROR: ", error!)
                    return
                }
                DatabaseService.shared.REF_BASE.child("users").child(uid).child("posts").observe(.childRemoved, with: { (snapshot) in
                    if let index = self.posts.index(where: {$0.postId == snapshot.key}) {
                        self.posts.remove(at: index)
//                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadData"), object: self)
                        self.tableView.reloadData()
                    } else {
                        self.tableView.reloadData()
                        print("item not found")
                    }
                })
            })
        }
    return [delete, pending]
    }
    
    
}



