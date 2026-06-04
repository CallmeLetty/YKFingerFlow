// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import BMAPI

//public class FingerFlowHistoryListTask: API<BMTAdhdAllFingerFlow> {
//  var page_no: Int
//
//  init(page_no: Int = 0) {
//    self.page_no = page_no
//    super.init()
//  }
//
//  public override var path: String {
//    return "/v1/adhd/all/challenge/\(userId)"
//  }
//
//  public override var method: RequestMethod {
//    return .get
//  }
//
//  public override var queryParams: [AnyHashable : Any] {
//    return ["type" : 2,
//            "page_no": page_no,
//            "page_size": 20]
//  }
//}
//
//public class FingerFlowBestResultTask: API<BMTAdhdFingerFlow> {
//
//  public override var path: String {
//    return "/v1/adhd/best/challenge/\(userId)"
//  }
//
//  public override var method: RequestMethod {
//    return .get
//  }
//
//  public override var queryParams: [AnyHashable : Any] {
//    return ["type" : 2]
//  }
//}
//
//public class FingerFlowUploadResultTask: API<BMTAdhdFingerFlow> {
//  var duration: Float
//  var resultImageUrl: String?
//  var shareUserId: Int?
//
//  public init(duration: Float,
//              resultImageUrl: String?,
//              shareUserId: Int? = nil) {
//    self.duration = duration
//    self.resultImageUrl = resultImageUrl
//    self.shareUserId = shareUserId
//    super.init()
//  }
//
//  public override var path: String {
//    return "/v1/adhd/challenge/\(userId)"
//  }
//
//  public override var method: RequestMethod {
//    return .put
//  }
//
//  public override var queryParams: [AnyHashable : Any] {
//    var params = ["type" : 2]
//    if let share = shareUserId {
//      params["sharer_user_id"] = share
//    }
//    return params
//  }
//
//  public override var bodyParams: Any {
//    if let resultImageUrl = resultImageUrl {
//      return ["request": ["duration": duration,
//                          "resultImageUrl": resultImageUrl].toJsonString() ?? ""]
//    }
//    return ["request": ["duration": duration].toJsonString() ?? ""]
//  }
//}
