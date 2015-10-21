//
//  IntroPageController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/20/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class IntroPageController: UIPageViewController {

	var identifiers: NSArray = ["Intro01", "Intro02", "Intro03"]
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		dataSource = self
		delegate = self
		
		let gradient = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)

		let startingViewController = viewControllerAtIndex(0)
		setViewControllers([startingViewController!], direction: .Forward, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func viewControllerAtIndex(index: Int) -> UIViewController? {
		return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(identifiers[index] as! String)
	}
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }

}

// MARK: - UIPageViewControllerDataSource
extension IntroPageController: UIPageViewControllerDataSource {
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = identifiers.indexOfObject(identifier!)
		if index == identifiers.count - 1 { return nil }
		index++
		return viewControllerAtIndex(index)
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = identifiers.indexOfObject(identifier!)
		if index == 0 { return nil }
		index--
		return self.viewControllerAtIndex(index)
	}
	
	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int  {
		return identifiers.count
	}
	
	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int  {
		return 0
	}
}

// MARK: - UIPageViewControllerDelegate
extension IntroPageController: UIPageViewControllerDelegate {
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

	}
}
