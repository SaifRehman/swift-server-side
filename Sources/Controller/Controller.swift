/**
* Copyright IBM Corporation 2016,2017
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
**/

import Kitura
import SwiftyJSON
import LoggerAPI
import CloudEnvironment
import Health
import PersonalityInsightsV3
import SwiftyJSON
import Foundation

public class Controller {

  public let router: Router
  let cloudEnv: CloudEnv
  let health: Health

  public var port: Int {
    get { return cloudEnv.port }
  }

  public var url: String {
    get { return cloudEnv.url }
  }

  public init() {
    // Create CloudEnv instance
    cloudEnv = CloudEnv()

    // All web apps need a Router instance to define routes
    router = Router()
    
    // Instance of health for reporting heath check values
    health = Health()

    // Serve static content from "public"
    router.all("/", middleware: StaticFileServer())

    // Basic GET request
    router.get("/hello", handler: getHello)

    // Basic POST request
    router.post("/hello", handler: postHello)

    // JSON Get request
    router.get("/json", handler: getJSON)
    
    // Basic application health check
    router.get("/health", handler: getHealthCheck)
  }

  /**
  * Handler for getting a text/plain response.
  */
  public func getHello(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) any {

    let username = "a86fdfae-0aeb-45e2-a5ee-2abcef27e879"
    let password = "CbwTsQxxGCZQ"
    let version = "2017-10-04" // use today's date for the most recent version

    let personalityInsights = PersonalityInsights(username: username, password: password, version: version)
    let text = "While GE’s Predix platform has been promoted on TV and covered in the New York Times and other leading publications, none of the press coverage has explained concretely what technology GE is building with Predix. This story will do just that based on my visit to the recent Predix Transform conference, interviews with people building applications using Predix, and work done creating content to explain Predix for GE. While GE’s Predix platform has been promoted on TV and covered in the New York Times and other leading publications, none of the press coverage has explained concretely what technology GE is building with Predix. This story will do just that based on my visit to the recent Predix Transform conference, interviews with people building applications using Predix, and work done creating content to explain Predix for GE."
    let failure = { (error: Error) in print(error) }
    personalityInsights.getProfile(fromText: text, failure: failure) { profile in 
        print(profile) 
      // let json = try? JSONSerialization.jsonObject(with: profile, options: [])
      // let jsonString = try? JSONSerialization.jsonObject(with: profile, options: []) as! [String: Any]
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        var jsonResponse = JSON([:])
//         jsonResponse["framework"].stringValue = "Kitura"
//         jsonResponse["applicationName"].stringValue = "Kitura-Starter"
//         jsonResponse["company"].stringValue = "IBM"
//         jsonResponse["organization"].stringValue = "Swift @ IBM"
//         jsonResponse["location"].stringValue = "Austin, Texas"
        try response.status(.OK).send(json: profile).end()
      }
  }

  /**
  * Handler for posting the name of the entity to say hello to (a text/plain response).
  */
  public func postHello(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    Log.debug("POST - /hello route handler...")
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    if let name = try request.readString() {
      try response.status(.OK).send("Hello \(name), from Kitura-Starter!").end()
    } else {
      try response.status(.OK).send("Kitura-Starter received a POST request!").end()
    }
  }

  /**
  * Handler for getting an application/json response.
  */
  public func getJSON(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    Log.debug("GET - /json route handler...")
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    var jsonResponse = JSON([:])
    jsonResponse["framework"].stringValue = "Kitura"
    jsonResponse["applicationName"].stringValue = "Kitura-Starter"
    jsonResponse["company"].stringValue = "IBM"
    jsonResponse["organization"].stringValue = "Swift @ IBM"
    jsonResponse["location"].stringValue = "Austin, Texas"
    try response.status(.OK).send(json: jsonResponse).end()
  }
    
  /**
   * Handler for getting a text/plain response of application health status.
   */
  public func getHealthCheck(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    Log.debug("GET - /health route handler...")
    let result = health.status.toSimpleDictionary()
    if health.status.state == .UP {
        try response.send(json: result).end()
    } else {
        try response.status(.serviceUnavailable).send(json: result).end()
    }
  }

}
