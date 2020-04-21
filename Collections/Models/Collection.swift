import FirebaseFirestore

struct Collection {
    /// The ID of the restaurant, generated from Firestore.
     var documentID: String

     /// The restaurant owner's uid. Corresponds to a user object in the top-level Users collection.
     var ownerID: String

     /// The name of the restaurant.
     var name: String
}

// MARK: - Firestore interoperability

extension Collection: DocumentSerializable {

  /// Initializes a restaurant with a documentID auto-generated by Firestore.
  init(ownerID: String,
       name: String) {
    let document = Firestore.firestore().collections.document()
    self.init(documentID: document.documentID,
              ownerID: ownerID,
              name: name)
  }

  /// Initializes a restaurant from a documentID and some data, ostensibly from Firestore.
  private init?(documentID: String, dictionary: [String: Any]) {
    guard let ownerID = dictionary["ownerID"] as? String,
        let name = dictionary["name"] as? String else { return nil }

    self.init(documentID: documentID,
              ownerID: ownerID,
              name: name)
  }

  init?(document: QueryDocumentSnapshot) {
    self.init(documentID: document.documentID, dictionary: document.data())
  }

  init?(document: DocumentSnapshot) {
    guard let data = document.data() else { return nil }
    self.init(documentID: document.documentID, dictionary: data)
  }

  /// The dictionary representation of the restaurant for uploading to Firestore.
  var documentData: [String: Any] {
    return [
      "ownerID": ownerID,
      "name": name
    ]
  }

}
