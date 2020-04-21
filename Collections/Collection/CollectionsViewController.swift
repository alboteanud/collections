import UIKit
import FirebaseAuth
import FirebaseUI
import FirebaseFirestore
import SDWebImage

let urlTermsOfService = URL(string: "https://sunshine-f15bf.firebaseapp.com/")!
let urlPrivacyPolicy = URL(string: "https://sunshine-f15bf.firebaseapp.com/")!

class CollectionsViewController: UIViewController {
    
    /// The current user displayed by the controller. Setting this property has side effects.
    fileprivate var user: User? = nil {
        didSet {
            populate(user: user)
            if let user = user {
                populateCollections(forUser: user)
            } else {
                dataSource?.stopUpdates()
                dataSource = nil
                tableView.backgroundView = tableBackgroundLabel
                tableView.reloadData()
            }
        }
    }
    
    lazy private var tableBackgroundLabel: UILabel = {
        let label = UILabel(frame: tableView.frame)
        label.textAlignment = .center
        return label
    }()
    
    private var dataSource: CollectionTableViewDataSource? = nil
    private var authListener: AuthStateDidChangeListenerHandle? = nil
    
    @IBOutlet private var tableView: UITableView!
    
    @IBOutlet private var profileImageView: UIImageView!
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var viewRestaurantsButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    // Not weak because we might remove it
    @IBOutlet var signOutButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableBackgroundLabel.text = "There aren't any collections here."
        tableView.backgroundView = tableBackgroundLabel
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUser(firebaseUser: Auth.auth().currentUser)
        Auth.auth().addStateDidChangeListener { (auth, newUser) in
            self.setUser(firebaseUser: newUser)
        }
    }
    
    @IBAction func didTapSignInButton(_ sender: Any) {
        print("sign in tapped")
        presentLoginController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    fileprivate func setUser(firebaseUser: FirebaseAuth.UserInfo?) {
        if let firebaseUser = firebaseUser {
            let user = User(user: firebaseUser)
            self.user = user
            Firestore.firestore().users.document(user.userID).setData(user.documentData) { error in
                if let error = error {
                    print("Error writing user to Firestore: \(error)")
                }
            }
        } else {
            user = nil
        }
    }
    
    fileprivate func populate(user: User?) {
        if let user = user {
            profileImageView.sd_setImage(with: user.photoURL)
            usernameLabel.text = user.name
            viewRestaurantsButton.isHidden = false
            signInButton.isHidden = true
            self.navigationItem.leftBarButtonItem = signOutButton
        } else {
            profileImageView.image = nil
            usernameLabel.text = "Sign in, why don'cha?"
            viewRestaurantsButton.isHidden = true
            signInButton.isHidden = false
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    fileprivate func populateCollections(forUser user: User) {
        let query = Firestore.firestore().collections.whereField("userInfo.userID", isEqualTo: user.userID)
        dataSource = CollectionTableViewDataSource(query: query) { [unowned self] (changes) in
            self.tableView.reloadData()
            guard let dataSource = self.dataSource else { return }
            if dataSource.count > 0 {
                self.tableView.backgroundView = nil
            } else {
                self.tableView.backgroundView = self.tableBackgroundLabel
            }
        }
        dataSource?.sectionTitle = "My Collections"
        dataSource?.startUpdates()
        tableView.dataSource = dataSource
    }
    
    fileprivate func presentLoginController() {
        guard let authUI = FUIAuth.defaultAuthUI() else { return }
        guard authUI.auth?.currentUser == nil else {
            print("Attempted to present auth flow while already logged in")
            return
        }
        
        FUIAuth.defaultAuthUI()?.tosurl = urlTermsOfService
        FUIAuth.defaultAuthUI()?.privacyPolicyURL = urlPrivacyPolicy
        
        authUI.providers = [
            FUIGoogleAuth(),
            FUIEmailAuth(),
            FUIOAuth.appleAuthProvider()
        ]
        
        let controller = authUI.authViewController()
        self.present(controller, animated: true, completion: nil)
    }
    
    @IBAction private func didTapSignOutButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch let error {
            print("Error signing out: \(error)")
        }
    }
    
}
