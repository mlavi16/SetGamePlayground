import UIKit
import PlaygroundSupport

class ViewController: UIViewController {

  override func loadView() {

    let view = UIView()
    view.backgroundColor = .white
    self.view = view

    let board = BoardView(frame: CGRect(x: 10, y: 70, width: 355, height: 600))
    board.cleanAndLoadBoard()
    board.boardHeading()
    view.addSubview(board)
  }
}

enum ShapeColor {
  case purple, red, green
  func uicolor() -> UIColor {
    switch self {
    case .purple: return UIColor.systemPurple
    case .red: return UIColor.systemRed
    case .green: return UIColor.systemGreen
    }
  }
  static var allColors: [ShapeColor] {
    return [.purple, .red, .green]
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

class CardView: UIButton {
  var boardView: BoardView?
  var cardData: CardData!
  override var isSelected: Bool {
    didSet {
      if isSelected {
        self.layer.borderColor = UIColor.systemBlue.cgColor
        self.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.06)
      } else {
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.backgroundColor = UIColor.white
      }
      boardView?.selectCard(cardData: cardData, selected: isSelected)
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.layer.borderColor = UIColor.lightGray.cgColor
    self.layer.borderWidth = 2
    self.layer.cornerRadius = 8

    self.addTarget(self, action: #selector(tappedCard(_:)), for: .touchUpInside)
  }

  func presentShapes(cardData: CardData) {
    self.cardData = cardData
    if let shapeImage = UIImage(named: cardData.geometry.rawValue + cardData.filling.rawValue) {

      let ratio = shapeImage.size.height / shapeImage.size.width
      let shapeWidth = max(bounds.width/6, 25)
      let shapeHeight = shapeWidth * ratio

      for i in 1...cardData.num.rawValue {

        let shapeImageView = UIImageView(image: shapeImage.withRenderingMode(.alwaysTemplate))
        shapeImageView.tintColor = cardData.color.uicolor()
        let shapesWidth = (shapeWidth * CGFloat(cardData.num.rawValue)) + 4 * (CGFloat(cardData.num.rawValue) - 1)

        var prevShape: CGFloat = 0
        if i == 2 {
          prevShape = shapeWidth + 4
        } else if i == 3 {
          prevShape = (shapeWidth + 4) * 2
        }

        let y = (bounds.height - shapeHeight) / 2
        let x = ((bounds.width - shapesWidth) / 2) + prevShape

        shapeImageView.frame = CGRect(x: x, y: y, width: shapeWidth, height: shapeHeight)
        addSubview(shapeImageView)
      }
    }
  }

  @objc func tappedCard(_ button: UIButton) {
    self.isSelected = !self.isSelected
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class BoardView: UIView {
  var selectedCards: [CardData] = []
  var boardCards: [CardData] = []
  var setCounter = 0
  let deck = DeckData()
  var hintCount = 0

  var messageView: MessageView!
  let counterLabel = UILabel()
  let hintButton = UIButton(type: .custom)

  func cleanAndLoadBoard() {
    self.boardCards = []
    self.selectedCards = []
    while getFirstSet(cards: boardCards) == nil {
      for subview in subviews {
        if let cardView = subview as? CardView {
          cardView.removeFromSuperview()
        }
      }
      loadBoard()
    }
  }

  private func loadBoard() {
    let headingHeight: CGFloat = 74
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
        let cardView = CardView(frame: frame)
        cardView.boardView = self
        if let cardData = deck.getRandomCard() {
          boardCards.append(cardData)
          cardView.presentShapes(cardData: cardData)
        }
        self.insertSubview(cardView, at: 0)
      }
    }
  }

  func boardHeading() {

    let fontSize: CGFloat = 16
    let space: CGFloat = 16

    hintButton.setTitle("Hint", for: .normal)
    hintButton.setTitleColor(UIColor.systemBlue, for: .normal)
    hintButton.addTarget(self, action: #selector(tappedHint(_:)), for: .touchUpInside)

    if let label = hintButton.titleLabel {
      label.font = UIFont.systemFont(ofSize: fontSize)
      label.sizeToFit()
      hintButton.frame = CGRect(x: 0, y: 10, width: label.frame.width, height: label.frame.height)
    }
    self.addSubview(hintButton)

    counterLabel.text = "Sets: " + String(setCounter)
    counterLabel.textColor = UIColor.systemPurple
    counterLabel.font = UIFont.systemFont(ofSize: fontSize)
    counterLabel.sizeToFit()
    counterLabel.frame = CGRect(x: hintButton.frame.maxX + space, y: 10, width: counterLabel.frame.width + 10, height: counterLabel.frame.height)
    self.addSubview(counterLabel)

    let howToPlayButton = UIButton(type: .custom)
    howToPlayButton.setTitle("How To Play", for: .normal)
    howToPlayButton.setTitleColor(UIColor.systemBlue, for: .normal)
    howToPlayButton.addTarget(self, action: #selector(tappedHowToPlay(_:)), for: .touchUpInside)

    if let label = howToPlayButton.titleLabel {
      label.font = UIFont.systemFont(ofSize: fontSize - 2)
      label.sizeToFit()
      howToPlayButton.frame = CGRect(x: counterLabel.frame.maxX + space, y: 10, width: label.frame.width, height: label.frame.height)
    }
    self.addSubview(howToPlayButton)

    let restartButton = UIButton(type: .custom)
    restartButton.setTitle("Restart Game", for: .normal)
    restartButton.setTitleColor(UIColor.systemBlue, for: .normal)
    restartButton.layer.borderColor = UIColor.lightGray.cgColor
    restartButton.layer.borderWidth = 1
    restartButton.addTarget(self, action: #selector(tappedRestart(_:)), for: .touchUpInside)

    if let label = restartButton.titleLabel {
      label.font = UIFont.systemFont(ofSize: fontSize)
      label.sizeToFit()
      restartButton.frame = CGRect(x: bounds.width - label.frame.width - 30, y: 6, width: label.frame.width + 20, height: label.frame.height + 10)
    }
    self.addSubview(restartButton)

    messageView = MessageView(frame: CGRect(x: 0, y: 60, width: bounds.width, height: bounds.height - 70))
    self.addSubview(messageView)
  }

  @objc func tappedHowToPlay(_ button: UIButton) {
    messageView.showHowToPlay()
  }

  @objc func tappedRestart(_ button: UIButton) {
    let board = BoardView(frame: frame)
    board.cleanAndLoadBoard()
    board.boardHeading()
    superview?.addSubview(board)
    self.removeFromSuperview()
  }

  @objc func tappedHint(_ button: UIButton) {
    guard let hintSet = getFirstSet(cards: boardCards) else { return }

    for subview in subviews {
      if let cardView = subview as? CardView {
        cardView.isSelected = false
        if hintCount < 2 && cardView.cardData.isEqual(to: hintSet.0) {
          cardView.isSelected = true
        } else if hintCount == 1 && cardView.cardData.isEqual(to: hintSet.1) {
          cardView.isSelected = true
        }
      }
    }

    if hintCount < 2 {
      hintCount += 1
    } else {
      messageView.showNoMoreHints()
      hintCount = 0
    }
  }

  func selectCard(cardData: CardData, selected: Bool) {
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
      hintCount = 0
      if checkSet() {
        setCounter += 1
        counterLabel.text = "Sets: " + String(setCounter)
        messageView.showSet {
          for selectedCard in self.selectedCards{
            let index = self.boardCards.firstIndex { cardData -> Bool in
              return cardData.isEqual(to: selectedCard)
              }
            if let index = index {
              self.boardCards.remove(at: index)
            }
          }
          self.selectedCards.removeAll()
          DispatchQueue.main.async {
            self.replaceSet()
          }
        }
      } else {
        messageView.showNotASet {
          for subview in self.subviews {
            if let cardView = subview as? CardView, cardView.isSelected {
              cardView.isSelected = false
            }
          }
        }
      }
    }
  }

  private func replaceSet() {
    for subview in subviews {
      if let cardView = subview as? CardView, cardView.isSelected {
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
    if getFirstSet(cards: boardCards) == nil {
      let setInDeck = getFirstSet(cards: deck.cards)
      if setInDeck == nil {
        messageView.showGameOver(counter: self.setCounter) {}
      } else {
        messageView.showNoSets {
          self.deck.cards.append(contentsOf: self.boardCards)
          self.cleanAndLoadBoard()
        }
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

    return colorSet && fillingSet && geometrySet && numSet  // || true
  }

  func getFirstSet(cards: [CardData]) -> (CardData, CardData, CardData)? {
    if cards.count < 3 {
      return nil
    }
    for cardA in 0..<(cards.count - 2) {
      for cardB in (cardA + 1)..<(cards.count - 1) {
        for cardC in (cardB + 1)..<cards.count {
          if checkSet(card1: cards[cardA], card2: cards[cardB], card3: cards[cardC]) {
            return (cards[cardA], cards[cardB], cards[cardC])
          }
        }
      }
    }
    return nil
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

class DeckData {
  var cards: [CardData] = []

  init() {
    generate()
  }

  private func generate() {
    cards = []
    for num in ShapeNum.allNums {
      for color in ShapeColor.allColors {
        for geometry in ShapeGeometry.allGeometry {
          for filling in ShapeFilling.allFillings {
          let cardData = CardData(num: num, color: color, filling: filling, geometry: geometry)
            cards.append(cardData)
          }
        }
      }
    }
  }

  func getRandomCard() -> CardData? {
    guard cards.count > 0 else {
      return nil
    }
    let randomInt = Int.random(in: 0..<cards.count)
    let card = cards.remove(at: randomInt)
    return card
  }
}

// Announcement View
class MessageView: UIView {

  let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.backgroundColor = UIColor.black.withAlphaComponent(0.4)

    let h: CGFloat = 300
    label.frame = CGRect(x: 16, y: (bounds.height - h) / 2, width: bounds.width - 32, height: h)
    label.numberOfLines = 0
    label.textAlignment = .center
    label.layer.cornerRadius = 30
    label.clipsToBounds = true
    label.textColor = .systemPurple
    label.backgroundColor = UIColor.white.withAlphaComponent(0.8)

    self.addSubview(label)

    self.alpha = 0
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func removeControls() {
    let button = self.subviews.first { view -> Bool in
      return view is UIButton
    }
    button?.removeFromSuperview()
    let button2 = self.subviews.first { view -> Bool in
      return view is UIButton
    }
    button2?.removeFromSuperview()
    let imageView = self.subviews.first { view -> Bool in
      return view is UIImageView
    }
    imageView?.removeFromSuperview()
  }

  private func animateMessage(duration: TimeInterval? = nil, completion: @escaping () -> Void) {
    UIView.animate(withDuration: 0.3, delay: 0.02, options: [], animations: {
      self.alpha = 1
    }) { (done) in

      guard let duration = duration else { return }

      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
        self.alpha = 0
        completion()
      }
    }
  }

  func showHowToPlay() {
    removeControls()

    label.font = UIFont.boldSystemFont(ofSize: 16)
    label.text = """
      The object of the game is
      to identify a SET of 3 cards.

      A SET consists of 3 cards in which each
      of the card's features (color, shape,
      fill and number of items), looked
      at one-by-one, are the same on each
      card, or, are different on each card.
    """

    let button = UIButton(type: .custom)
    button.frame = CGRect(x: 0, y: label.frame.minY - 60, width: bounds.width, height: 50)
    button.setTitle("Close", for: .normal)
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
    button.addTarget(self, action: #selector(tappedClose(_:)), for: .touchUpInside)
    self.addSubview(button)

    let examplesButton = UIButton(type: .custom)
    examplesButton.frame = CGRect(x: 0, y: label.frame.maxY - 60, width: bounds.width, height: 50)
    examplesButton.setTitle("Examples", for: .normal)
    examplesButton.setTitleColor(UIColor.systemBlue, for: .normal)
    examplesButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
    examplesButton.addTarget(self, action: #selector(tappedExamples(_:)), for: .touchUpInside)
    self.addSubview(examplesButton)

    animateMessage {}
  }

  func showSet(duration: TimeInterval = 0.5, completion: @escaping () -> Void) {
    label.text = "SET!"
    label.font = UIFont.boldSystemFont(ofSize: 80)
    removeControls()
    animateMessage(duration: duration, completion: completion)
  }

  func showNotASet(duration: TimeInterval = 0.5, completion: @escaping () -> Void) {
    label.text = "Not a set \n\n Try again..."
    label.font = UIFont.boldSystemFont(ofSize: 50)
    removeControls()
    animateMessage(duration: duration, completion: completion)
  }

  func showGameOver(counter: Int, completion: @escaping () -> Void) {
    label.text = "Game Over \n You got: \(counter) sets!"
    label.font = UIFont.boldSystemFont(ofSize: 50)
    removeControls()
    animateMessage(completion: completion)
  }

  func showNoSets(duration: TimeInterval = 2, completion: @escaping () -> Void) {
    label.text = "No sets found \nReshuffling..."
    label.font = UIFont.boldSystemFont(ofSize: 50)
    removeControls()
    animateMessage(duration: duration, completion: completion)
  }

  func showNoMoreHints(duration: TimeInterval = 4) {
    print("no more hints..")
    label.text = "Only two hints per set. \nFollow the rules to find the \nlast card for this set."
    label.font = UIFont.boldSystemFont(ofSize: 20)
    removeControls()
    animateMessage(duration: duration, completion: {})
  }

  @objc func tappedExamples(_ button: UIButton) {
    if let examplesImage = UIImage(named: "examples") {
      let examplesImageView = UIImageView(image: examplesImage)
      examplesImageView.frame = label.frame
      self.addSubview(examplesImageView)
    }
  }

  @objc func tappedClose(_ button: UIButton) {
    UIView.animate(withDuration: 0.5) {
      self.alpha = 0
    }
  }
}


// Present the view controller in the Live View window
PlaygroundPage.current.liveView = ViewController()
