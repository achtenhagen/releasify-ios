
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
		
		// Navigation bar customization.
		let image = UIImage(named: "navBar.png")
		navBar.setBackgroundImage(image, forBarMetrics: UIBarMetrics.Default)
		navBar.shadowImage = UIImage()
		navBar.translucent = true
		
		println("App Controller loaded.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}