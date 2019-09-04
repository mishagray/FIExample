//
//  Restaurant.swift
//  FiExample
//
//  Created by Michael Gray on 9/1/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

// This file was (originally) generated from JSON Schema using quicktype.
// To parse the JSON, add this file to your project and do:
//
//   let decoder = JSONDecoder()
//   decoder.dateDecodingStrategy = .secondsSince1970
//   let resturant = try? newJSONDecoder().decode(Resturant.self, from: jsonData)

import Foundation

// swiftlint:disable identifier_name

// MARK: - Restaurant
// REQUIRES JSONDecoder().dateDecodingStrategy = .secondsSince1970

struct Restaurant: Codable {
    let address: Address
    let borough: Borough
    let cuisine: Cuisine

    // swiftlint:disable:next todo
    // TODO: convert Cuisine to String with a dynamic computed 'allCases' equivilant.
    // we can have a list of cuisines to filter by, without the threat of new cusines being added server-side.
    let grades: [Inspection]
    let name, restaurantID: String

    enum CodingKeys: String, CodingKey {
        case address, borough, cuisine, grades, name
        case restaurantID = "restaurant_id"
    }
}

// MARK: - Address
struct Address: Codable {
    let building: String
    let coord: [Double]
    let street, zipcode: String
}

enum Borough: String, CaseIterable, Codable {
    case bronx = "Bronx"
    case brooklyn = "Brooklyn"
    case manhattan = "Manhattan"
    case missing = "Missing"
    case queens = "Queens"
    case statenIsland = "Staten Island"
}

// Not sure this should be an Enum...
// Probably just a simple string.  The value add of an enum is not deserved
// Although we will have to code our own dynamic logic of 'CaseIterable.allCases' (we need it for filtering).
enum Cuisine: String, CaseIterable, Codable {
    case afghan = "Afghan"
    case african = "African"
    case american = "American"
    case armenian = "Armenian"
    case asian = "Asian"
    case australian = "Australian"
    case bagelsPretzels = "Bagels/Pretzels"
    case bakery = "Bakery"
    case bangladeshi = "Bangladeshi"
    case barbecue = "Barbecue"
    case bottledBeveragesIncludingWaterSodasJuicesEtc = "Bottled beverages, including water, sodas, juices, etc."
    case brazilian = "Brazilian"

    // bleh.   Stupid Goverment Databases Duplicates.
    // Do we attempt to clean this up?  Should really be fixed server-side.
    case cafÃCoffeeTea = "CafÃ©/Coffee/Tea"
    case caféCoffeeTea = "Café/Coffee/Tea"

    case cajun = "Cajun"
    case californian = "Californian"
    case caribbean = "Caribbean"
    case chicken = "Chicken"
    case chilean = "Chilean"
    case chinese = "Chinese"
    case chineseCuban = "Chinese/Cuban"
    case chineseJapanese = "Chinese/Japanese"
    case continental = "Continental"
    case creole = "Creole"
    case creoleCajun = "Creole/Cajun"
    case czech = "Czech"
    case delicatessen = "Delicatessen"
    case donuts = "Donuts"
    case easternEuropean = "Eastern European"
    case egyptian = "Egyptian"
    case english = "English"
    case ethiopian = "Ethiopian"
    case filipino = "Filipino"
    case french = "French"
    case fruitsVegetables = "Fruits/Vegetables"
    case german = "German"
    case greek = "Greek"
    case hamburgers = "Hamburgers"
    case hawaiian = "Hawaiian"
    case hotdogs = "Hotdogs"
    case hotdogsPretzels = "Hotdogs/Pretzels"
    case iceCreamGelatoYogurtIces = "Ice Cream, Gelato, Yogurt, Ices"
    case indian = "Indian"
    case indonesian = "Indonesian"
    case iranian = "Iranian"
    case irish = "Irish"
    case italian = "Italian"
    case japanese = "Japanese"
    case jewishKosher = "Jewish/Kosher"
    case juiceSmoothiesFruitSalads = "Juice, Smoothies, Fruit Salads"
    case korean = "Korean"
    case latinCubanDominicanPuertoRicanSouthCentralAmerican
        = "Latin (Cuban, Dominican, Puerto Rican, South & Central American)"
    case mediterranean = "Mediterranean"
    case mexican = "Mexican"
    case middleEastern = "Middle Eastern"
    case moroccan = "Moroccan"
    case notListedNotApplicable = "Not Listed/Not Applicable"
    case nutsConfectionary = "Nuts/Confectionary"
    case other = "Other"
    case pakistani = "Pakistani"
    case pancakesWaffles = "Pancakes/Waffles"
    case peruvian = "Peruvian"
    case pizza = "Pizza"
    case pizzaItalian = "Pizza/Italian"
    case polish = "Polish"
    case polynesian = "Polynesian"
    case portuguese = "Portuguese"
    case russian = "Russian"
    case salads = "Salads"
    case sandwiches = "Sandwiches"
    case sandwichesSaladsMixedBuffet = "Sandwiches/Salads/Mixed Buffet"
    case scandinavian = "Scandinavian"
    case seafood = "Seafood"
    case soulFood = "Soul Food"
    case soups = "Soups"
    case soupsSandwiches = "Soups & Sandwiches"
    case southwestern = "Southwestern"
    case spanish = "Spanish"
    case steak = "Steak"
    case tapas = "Tapas"
    case texMex = "Tex-Mex"
    case thai = "Thai"
    case turkish = "Turkish"
    case vegetarian = "Vegetarian"
    case vietnameseCambodianMalaysia = "Vietnamese/Cambodian/Malaysia"
}

// MARK: - GradeElement
struct Inspection: Codable {
    let date: InspectionDate
    let grade: Grade
    let score: Int?
}

// MARK: - DateClass
struct InspectionDate: Codable {
    let date: Date

    enum CodingKeys: String, CodingKey {
        case date = "$date"
    }
}

enum Grade: String, CaseIterable, Codable {
    case a = "A"
    case b = "B"
    case c = "C"
    case notYetGraded = "Not Yet Graded"
    case p = "P"
    case z = "Z"
}
