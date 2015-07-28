
import UIKit

class AppController: UINavigationController {

	@IBOutlet weak var navBar: UINavigationBar!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		// Todo: migrate initialization code from AppDelegate to AppController.
		println("App Controller loaded.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}