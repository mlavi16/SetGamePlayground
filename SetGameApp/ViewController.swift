import UIKit

enum ShapeColor {
  case purple, red, orange
  func uicolor() -> UIColor {
    switch self {
    case .purple: return UIColor.systemPurple
    case .red: return UIColor.systemRed
    case .orange: return UIColor.systemIndigo
    }
  }
  static var allColors: [ShapeColor] {
    return [.purple, .red, .orange]
  }
}
enum ShapeNum: Int {
  case one = 1, two, three
  static var allNums: [ShapeNum] {
    return [.one, .two, .three]
  }
}
enum ShapeGeometry: String {
  case oval = "set-shape-oval-", diamond = "set-shape-diamond-", squiggly = "set-shape-squiggle-"
  static var allGeometry: [ShapeGeometry] {
    return [.oval, .diamond, .squiggly]
  }
}
enum ShapeFilling: String {
  case full = "full", striped = "striped", empty = "empty"
  static var allFillings: [ShapeFilling] {
    return [.full, .striped, .empty]
  }
}

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    let button = UIButton(type: UIButton.ButtonType.infoLight)
    button.frame = CGRect(x: 10, y: 60, width: 60, height: 40)
    view.addSubview(button)

    let board = SetBoard(frame: CGRect(x: 10, y: 100, width: view.bounds.width - 20, height: view.bounds.height - 110))
    board.cleanAndLoadBoard()
    board.boardHeading()
    view.addSubview(board)

    let deck = SetDeck()
    deck.generate()
    print(deck.cards.count)
  }
}

class SetCard: UIButton {
  var setBoard: SetBoard?
  var cardData: CardData!
  override var isSelected: Bool {
      didSet {
          if isSelected {
            self.layer.borderColor = UIColor.blue.cgColor
            self.backgroundColor = UIColor.blue.withAlphaComponent(0.03)
          } else {
            self.layer.borderColor = UIColor.black.cgColor
            self.backgroundColor = UIColor.white
          }
          setBoard?.selectCard(cardData: cardData, selected: isSelected)

      }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.layer.borderColor = UIColor.black.cgColor
    self.layer.borderWidth = 2
    self.layer.cornerRadius = 8

    self.addTarget(self, action: #selector(tappedCard), for: .touchUpInside)
  }

  func presentShapes(cardData: CardData) {
    self.cardData = cardData
    if let shapeImage = UIImage(named: cardData.geometry.rawValue + cardData.filling.rawValue) {
      for i in 1...cardData.num.rawValue {

        let shapeImageView = UIImageView(image: shapeImage.withRenderingMode(.alwaysTemplate))
        shapeImageView.tintColor = cardData.color.uicolor()
        let shapesWidth = (shapeImage.size.width * CGFloat(cardData.num.rawValue)) + 4 * (CGFloat(cardData.num.rawValue) - 1)

        var prevShape: CGFloat = 0
        if i == 2 {
          prevShape = shapeImage.size.width + 4
        } else if i == 3 {
          prevShape = (shapeImage.size.width + 4) * 2
        }
        
        let y = (self.frame.height - shapeImage.size.height) / 2
        let x = ((self.frame.width - shapesWidth) / 2) + prevShape

        shapeImageView.frame = CGRect(x: x, y: y, width: shapeImage.size.width, height: shapeImage.size.height)
        addSubview(shapeImageView)
      }
    }
  }

  @objc func tappedCard() {
    self.isSelected = !self.isSelected
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class SetBoard: UIView {
  var selectedCards: [CardData] = []
  var boardCards: [CardData] = []
  var setCounter = 0
  let counterLabel = UILabel()
  let announcementLabel = UILabel()
  let deck = SetDeck()

  func cleanAndLoadBoard() {
    while !hasAnySet() {
      for subview in subviews {
        if let cardView = subview as? SetCard {
          cardView.removeFromSuperview()
        }
      }
      loadBoard()
    }
  }

  func loadBoard() {
    let headingHeight: CGFloat = 60
    let colNum: CGFloat = 3
    let rowNum: CGFloat = 4
    let sp: CGFloat = 8
    let cardWidth = (self.bounds.width - (sp * (colNum-1))) / colNum
    let cardHeight = (self.bounds.height - (sp * (rowNum-1)) - headingHeight - 10) / rowNum
    for col in 0..<Int(colNum) {
      for row in 0..<Int(rowNum) {
        let x = (cardWidth + sp) * CGFloat(col)
        let y = (cardHeight + sp) * CGFloat(row) + headingHeight
        let frame = CGRect(x: x, y: y, width: cardWidth, height: cardHeight)
        let cardView = SetCard(frame: frame)
        cardView.setBoard = self
        if let cardData = deck.getRandomCard() {
          boardCards.append(cardData)
          cardView.presentShapes(cardData: cardData)
        }
        self.addSubview(cardView)
      }
    }
  }

  func animateSet(completion: @escaping () -> Void) {
    self.isUserInteractionEnabled = false
    UIView.animate(withDuration: 1, delay: 0.1, options: [], animations: {
      self.announcementLabel.alpha = 1
    }) { (done) in
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
        self.announcementLabel.alpha = 0
        self.isUserInteractionEnabled = true
        completion()
      }
    }
  }

  func boardHeading() {
    counterLabel.frame = CGRect(x: 10, y: 0, width: self.bounds.width, height: 60)
    counterLabel.text = "Sets: " + String(setCounter)
    self.addSubview(counterLabel)

    announcementLabel.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
    announcementLabel.text = "SET"
    announcementLabel.font = UIFont.boldSystemFont(ofSize: 80)
    announcementLabel.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
    announcementLabel.textAlignment = .center
    announcementLabel.alpha = 0
    self.addSubview(announcementLabel)

  }

  func selectCard(cardData: CardData, selected: Bool) {
    print("card is selected", cardData, selected)
    if selected {
      selectedCards.append(cardData)
    } else {
      let ind = selectedCards.firstIndex { (cd) -> Bool in
        return cd.color == cardData.color && cd.filling == cardData.filling && cd.geometry == cardData.geometry && cd.num == cardData.num
      }
      if let ind = ind {
        selectedCards.remove(at: ind)
      }
    }
    if selectedCards.count >= 3 {
      if checkSet() {
        setCounter += 1
        counterLabel.text = "Sets: " + String(setCounter)
        announcementLabel.text = "SET"
        animateSet {
          for selectedCard in self.selectedCards{
            let index = self.boardCards.firstIndex { cardData -> Bool in
              return cardData.isEqual(to: selectedCard)
              }
            if let index = index {
              self.boardCards.remove(at: index)
            }
          }
          self.selectedCards.removeAll()
          self.replaceSet()
        }
      } else {
        // TODO: show not a set message
        print("not a set")
        for subview in subviews {
          if let cardView = subview as? SetCard, cardView.isSelected {
            cardView.isSelected = false
          }
        }
      }
    }
  }

  func replaceSet() {
    for subview in subviews {
      if let cardView = subview as? SetCard, cardView.isSelected {
        cardView.isSelected = false
        for sv in cardView.subviews {
          sv.removeFromSuperview()
        }
        if let cardData = deck.getRandomCard() {
          boardCards.append(cardData)
          cardView.presentShapes(cardData: cardData)
        }
      }
    }
    while !hasAnySet() {
      announcementLabel.text = "No sets found /n Reshuffling"
      animateSet {
        self.cleanAndLoadBoard()
      }
    }
  }

  func checkSet() -> Bool {
    return checkSet(card1: selectedCards[0], card2: selectedCards[1], card3: selectedCards[2])
  }

  func checkSet(card1: CardData, card2: CardData, card3: CardData) -> Bool {
    let colorSet = ((card1.color == card2.color) && (card1.color == card3.color)) || ((card1.color != card2.color) && (card1.color != card3.color) && (card2.color != card3.color))
    let fillingSet = ((card1.filling == card2.filling) && (card1.filling == card3.filling)) || ((card1.filling != card2.filling) && (card1.filling != card3.filling) && (card2.filling != card3.filling))
    let geometrySet = ((card1.geometry == card2.geometry) && (card1.geometry == card3.geometry)) || ((card1.geometry != card2.geometry) && (card1.geometry != card3.geometry) && (card2.geometry != card3.geometry))
    let numSet = ((card1.num == card2.num) && (card1.num == card3.num)) || ((card1.num != card2.num) && (card1.num != card3.num) && (card2.num != card3.num))

    return colorSet && fillingSet && geometrySet && numSet
  }

  func hasAnySet() -> Bool{
    if boardCards.count == 0 {
      return false
    }
    for cardA in 0..<(boardCards.count - 2) {
      for cardB in 1..<(boardCards.count - 1) {
        for cardC in 2..<boardCards.count {
          if checkSet(card1: boardCards[cardA], card2: boardCards[cardB], card3: boardCards[cardC]) {
            return true
          }
        }
      }
    }
    return false
  }
}

struct CardData {
  let num: ShapeNum
  let color: ShapeColor
  let filling: ShapeFilling
  let geometry: ShapeGeometry

  func isEqual(to cardData: CardData) -> Bool {
    return num == cardData.num && color == cardData.color && filling == cardData.filling && geometry == cardData.geometry
  }
}

class SetDeck {
  var cards: [CardData] = []

  init() {
    generate()
  }

  func generate() {
    for num in ShapeNum.allNums {
      for color in ShapeColor.allColors {
        for geometry in ShapeGeometry.allGeometry {
//          for filling in ShapeFilling.allFillings {
        let cardData = CardData(num: num, color: color, filling: .empty, geometry: geometry)
            cards.append(cardData)
          }
        }
      }
    }
//  }

  func getRandomCard() -> CardData? {
    guard cards.count > 0 else {
      return nil
    }
    let randomInt = Int.random(in: 0..<cards.count)
    let card = cards.remove(at: randomInt)
    return card
  }
}

