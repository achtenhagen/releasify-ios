//
//  IntroPageController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/21/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

protocol IntroPageDelegate: class {
	func advanceIntroPageTo (index: Int, reverse: Bool)
}

class IntroPageController: UIPageViewController, UIPageViewControllerDelegate {

	let storyBoard = UIStoryboard(name: "Main", bundle: nil)
	var introPage01: Intro01Controller?
	var introPage02: Intro02Controller?
	var introPage03: Intro03Controller?
	var introPage04: Intro04Controller?
	var imageView: UIImageView!
	var currentIndex = 0
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		dataSource = self
		delegate = self
		
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
		
		introPage01 = storyBoard.instantiateViewControllerWithIdentifier("Intro01") as? Intro01Controller
		introPage01!.delegate = self
		let viewControllers = NSArray(object: introPage01!)
		
		setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Return index for view controller restoration identifier
	func indexForRestorationIdentifier (restorationIdentifier: String) -> Int {
		switch restorationIdentifier {
		case "Intro02":
			return 1
		case "Intro03":
			return 2
		case "Intro04":
			return 3
		default:
			return 0
		}
	}
	
	// MARK: - Return view controller for index
	func viewControllerAtIndex(index: Int) -> UIViewController {
		switch index {
		case 1:
			if introPage02 == nil {
				introPage02 = storyBoard.instantiateViewControllerWithIdentifier("Intro02") as? Intro02Controller
			}
			introPage02?.delegate = self
			return introPage02!
		case 2:
			if introPage03 == nil {
				introPage03 = storyBoard.instantiateViewControllerWithIdentifier("Intro03") as? Intro03Controller
				introPage03?.delegate = self
			}
			return introPage03!
		case 3:
			if introPage04 == nil {
				introPage04 = storyBoard.instantiateViewControllerWithIdentifier("Intro04") as? Intro04Controller
			}
			introPage04?.delegate = self
			return introPage04!
		default:
			return introPage01!
		}
	}
}

// MARK: - UIPageViewControllerDataSource
extension IntroPageController: UIPageViewControllerDataSource {
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = indexForRestorationIdentifier(identifier!)
		if index == 3 { return nil }
		index++
		return viewControllerAtIndex(index)
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = indexForRestorationIdentifier(identifier!)
		if index == 0 { return nil }
		index--
		return viewControllerAtIndex(index)
	}
	
	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int  {
		return 4
	}
	
	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int  {
		return currentIndex
	}
}

// MARK: - IntroPageDelegate
extension IntroPageController: IntroPageDelegate {
	func advanceIntroPageTo(index: Int, reverse: Bool = false) {
		let viewControllers: NSArray
		switch index {
		case 2:
			let startVC = viewControllerAtIndex(1) as! Intro02Controller
			viewControllers = NSArray(object: startVC)
		case 3:
			let startVC = viewControllerAtIndex(2) as! Intro03Controller
			viewControllers = NSArray(object: startVC)
		case 4:
			let startVC = viewControllerAtIndex(3) as! Intro04Controller
			viewControllers = NSArray(object: startVC)
		default:
			let startVC = viewControllerAtIndex(0) as! Intro01Controller
			viewControllers = NSArray(object: startVC)
		}
		currentIndex = index-1
		if reverse {
			setViewControllers(viewControllers as? [UIViewController], direction: .Reverse, animated: true, completion: nil)
		} else {
			setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
		}
	}
}
