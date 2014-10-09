//
//  Observable.swift
//  IndoorLocalization
//
//  Created by Thomas Bopst on 08/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

@objc protocol Observable {
    func addObserver(o: Observer)
    func removeObserver(o: Observer)
    func notifyObservers()
}