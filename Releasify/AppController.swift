
import UIKit

class AppController: UINavigationController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	
	@IBOutlet weak var navBar: UINavigationBar!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Load data from database.
		AppDB.sharedInstance.getArtists()
		AppDB.sharedInstance.getAlbums()
		
		// Check for any pending artists waiting to be removed.
		let pendingArtists = AppDB.sharedInstance.getPendingArtists()
		
		// Navigation bar background.
		var navigationBar = UINavigationBar.appearance()
		let image = UIImage(named: "navBar.png")
		navigationBar.setBackgroundImage(image, forBarMetrics: UIBarMetrics.Default)
		navigationBar.shadowImage = UIImage()
		navigationBar.translucent = true
		
		println("App Controller loaded.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
}