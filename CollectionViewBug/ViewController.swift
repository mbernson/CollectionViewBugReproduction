//
//  ViewController.swift
//  CollectionViewBug
//
//  Created by Mathijs on 22/02/2021.
//

import UIKit
import Foundation
import DiffableDataSources

struct Screen {
  var sections: [Section]
}

struct Section {
  let id: String
  var rows: [Row]
}

struct Row {
  let id: String
  var items: [Item]
}

struct Item {
  let id: Int
  let color: UIColor
  var state: Bool = false
}

let colors: [UIColor] = [
  .systemRed,
  .systemOrange,
  .systemYellow,
  .systemGreen,
  .systemBlue,
  .systemIndigo,
  .systemPink,
  .systemPurple,
  .systemTeal,
]

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  var dataSource: CollectionViewDiffableDataSource<String, String>!
  let layout: UICollectionViewFlowLayout
  var screen = Screen(sections: [
    Section(id: "section1", rows: [
      Row(id: "row1", items: colors.enumerated().map { index, color in Item(id: index, color: color) })
    ]),
    Section(id: "section2", rows: [
      Row(id: "row2", items: colors.enumerated().map { index, color in Item(id: index, color: color) }.reversed())
    ]),
  ])

  init() {
    layout = UICollectionViewFlowLayout()
    super.init(collectionViewLayout: layout)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(update))

    dataSource = CollectionViewDiffableDataSource<String, String>(collectionView: collectionView) { collectionView, indexPath, itemIdentifierType in
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCell.reuseIdentifier, for: indexPath) as? CarouselCell

      let row = self.screen.sections[indexPath.section].rows[indexPath.row]
      print("Reloading cell at \(indexPath)")

      cell?.items = row.items
      cell?.didSelect = { [weak self] index, newState in
        print("Selected")
        print(row.items[index])
        self?.screen.sections[indexPath.section].rows[indexPath.row].items[index].state.toggle()
        self?.update(at: indexPath)
      }
      return cell
    }

    layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

    collectionView.backgroundColor = .systemBackground
    collectionView.register(CarouselCell.self, forCellWithReuseIdentifier: CarouselCell.reuseIdentifier)
    collectionView.dataSource = dataSource

    var snapshot = dataSource.snapshot()
    snapshot.appendSections(screen.sections.map(\.id))

    for section in screen.sections {
      snapshot.appendItems(section.rows.map(\.id), toSection: section.id)
    }

    dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: 200)
  }

  @objc func update(at indexPath: IndexPath) {
    print("Requesting reload of cell \(indexPath)")

    var snapshot = dataSource.snapshot()

    snapshot.reloadItems([screen.sections[indexPath.section].rows[indexPath.row].id])

    dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
  }
}

class CollectionViewCell: UICollectionViewCell {
  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initialize()
  }

  func initialize() {}
}

class CarouselCell: CollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  static let reuseIdentifier = "CarouselCell"

  var collectionView: UICollectionView!
  var items: [Item] = [] {
    didSet {
      collectionView.reloadData()
      print("CarouselCell: reloading data")
    }
  }
  var didSelect: ((Int, Bool) -> Void)?

  override func initialize() {
    super.initialize()

    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal

    collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
    collectionView.backgroundColor = .systemBackground
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(CarouselItemCell.self, forCellWithReuseIdentifier: CarouselItemCell.reuseIdentifier)
    addSubview(collectionView)
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselItemCell.reuseIdentifier, for: indexPath) as! CarouselItemCell
    let item = items[indexPath.row]
    cell.contentView.backgroundColor = item.color
    cell.label.text = item.state ? "On" : "Off"
    print("Reloading carousel cell at \(indexPath)")
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: bounds.width / 3, height: bounds.height)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let item = items[indexPath.row]
    didSelect?(indexPath.row, !item.state)
  }
}

class CarouselItemCell: CollectionViewCell {
  static let reuseIdentifier = "CarouselItemCell"

  let label = UILabel()

  override func initialize() {
    super.initialize()
    contentView.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
    ])
  }
}
