
import UIKit

class AppController: UINavigationController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	
	@IBOutlet weak var navBar: UINavigationBar!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		println("App Controller loaded.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}