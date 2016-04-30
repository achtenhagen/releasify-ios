//
//  AlbumCollectionViewLayout.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 4/30/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AlbumCollectionViewLayout: UICollectionViewFlowLayout {
	override init() {
		super.init()
		let defaultItemSize = CGSize(width: 145, height: 190)
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			itemSize = defaultItemSize
		case 375:
			itemSize = CGSize(width: 172.5, height: 217.5)
		case 414:
			itemSize = CGSize(width: 192, height: 237)
		default:
			itemSize = defaultItemSize
		}
		sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		minimumLineSpacing = 10
		minimumInteritemSpacing = 10
	}

	required init?(coder aDecoder: NSCoder) {
		super.init()
	}
}
