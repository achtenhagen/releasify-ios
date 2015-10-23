//
//  IntroPageController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/21/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class IntroPageController: UIPageViewController {

	let identifiers: NSArray = ["Intro01", "Intro02", "Intro03"]
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		dataSource = self
		delegate = self

		let bgImage: UIImage!
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			bgImage = UIImage(named: "Intro_bg_iPhone5.png");
		case 375:
			bgImage = UIImage(named: "Intro_bg_iPhone6.png");
		case 540:
			bgImage = UIImage(named: "Intro_bg_iPhone6_plus.png");
		default:
			bgImage = UIImage(named: "Intro_bg.png");
		}
		
		let imageView   = UIImageView(frame: view.bounds);
		imageView.image = bgImage
		view.addSubview(imageView)
		view.sendSubviewToBack(imageView)
		
		let startVC = viewControllerAtIndex(0) as UIViewController
		let viewControllers = NSArray(object: startVC)
		
		setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func viewControllerAtIndex(index: Int) -> UIViewController {
		return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(identifiers[index] as! String)
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
		return viewControllerAtIndex(index)
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