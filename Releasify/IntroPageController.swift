//
//  IntroPageController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/21/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

protocol IntroPageDelegate: class {
	func advanceIntroPageTo (index: Int)
}

class IntroPageController: UIPageViewController {

	let identifiers: NSArray = ["Intro01", "Intro02", "Intro03", "Intro04"]
	var currentIndex = 0
	var imageView = UIImageView()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		dataSource = self
		delegate = self
		
		view.backgroundColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
		
		let bgImage: UIImage!
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			bgImage = UIImage(named: "Intro_bg_iPhone5.png")
		case 375:
			bgImage = UIImage(named: "Intro_bg_iPhone6.png")
		case 414:
			bgImage = UIImage(named: "Intro_bg_iPhone6_plus.png")
		default:
			bgImage = UIImage(named: "Intro_bg.png")
		}
		
		imageView = UIImageView(frame: view.bounds)
		imageView.image = bgImage
		view.addSubview(imageView)
		view.sendSubviewToBack(imageView)
		
		let startVC = viewControllerAtIndex(0) as! Intro01Controller
		startVC.delegate = self
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
		return currentIndex
	}
}

// MARK: - UIPageViewControllerDelegate
extension IntroPageController: UIPageViewControllerDelegate {
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		if completed {
			let currentView = pageViewController.viewControllers![0]
			if currentView.isKindOfClass(Intro02Controller) {
				print("Delegate is now page controller 2")
			} else if currentView.isKindOfClass(Intro03Controller) {
				print("Delegate is now page controller 3")
			} else if currentView.isKindOfClass(Intro04Controller) {
				print("Delegate is now page controller 4")
			} else {
				print("Delegate is now page controller 1")
			}
		}
	}
}

// MARK: - IntroPageDelegate
extension IntroPageController: IntroPageDelegate {
	func advanceIntroPageTo(index: Int) {
		let viewControllers: NSArray
		switch index {
		case 2:
			let startVC = viewControllerAtIndex(1) as! Intro02Controller
			startVC.delegate = self
			viewControllers = NSArray(object: startVC)
			print(startVC)
			print(startVC.delegate)
			print("Delegate is now page controller 2 (Pressed Button)")
		case 3:
			let startVC = viewControllerAtIndex(2) as! Intro03Controller
			startVC.delegate = self
			viewControllers = NSArray(object: startVC)
		case 4:
			let startVC = viewControllerAtIndex(3) as! Intro04Controller
			startVC.delegate = self
			viewControllers = NSArray(object: startVC)
		default:
			let startVC = viewControllerAtIndex(0) as! Intro01Controller
			startVC.delegate = self
			viewControllers = NSArray(object: startVC)
		}
		currentIndex = index-1
		setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
	}
}
