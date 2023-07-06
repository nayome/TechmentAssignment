//
//  HomeViewModel.swift
//  TechmentAssignment
//
//  Created by NayomeDevapriyaAnga on 03/07/23.
//  Copyright © 2023 NayomeDevapriyaAnga. All rights reserved.
//

import Foundation

class HomeViewModel {
    var searchString: String
    private var apiService: APIService!
    
    private (set) var apiData: [ItemDetail]? {
        didSet {
            self.bindProgViewModelToController()
        }
    }
    
    var bindProgViewModelToController : (() -> ()) = {}
    
    init(searchString: String) {
        //super.init()
        self.searchString = searchString
        self.apiService = APIService()
        
        callFuncToFetchProgLangList(withText:self.searchString)
    }
    
    
    
    
    func callFuncToFetchProgLangList(withText: String){
        self.apiService.fetchProgrammingLanguages(withKeyword: withText,completion: { ( itemsList) in
            print(itemsList)
            self.apiData = itemsList
        })
    }
}
