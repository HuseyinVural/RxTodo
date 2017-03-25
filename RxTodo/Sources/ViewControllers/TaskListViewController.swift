//
//  TaskListViewController.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 7/1/16.
//  Copyright © 2016 Suyeol Jeon. All rights reserved.
//

import UIKit

import RxCocoa
import RxDataSources
import RxSwift
import ReusableKit

final class TaskListViewController: BaseViewController, ViewType {

  typealias Reactor = TaskListViewReactor


  // MARK: Constants

  struct Reusable {
    static let taskCell = ReusableCell<TaskCell>()
  }


  // MARK: Properties

  fileprivate let reactor: Reactor
  let dataSource = RxTableViewSectionedReloadDataSource<TaskListSection>()

  let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
  let tableView = UITableView().then {
    $0.allowsSelectionDuringEditing = true
    $0.register(Reusable.taskCell)
  }


  // MARK: Initializing

  init(reactor: TaskListViewReactor) {
    self.reactor = reactor
    super.init()
    self.navigationItem.leftBarButtonItem = self.editButtonItem
    self.navigationItem.rightBarButtonItem = self.addButtonItem
    self.configure(reactor: reactor)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.view.addSubview(self.tableView)
  }

  override func setupConstraints() {
    super.setupConstraints()
    self.tableView.snp.makeConstraints { make in
      make.edges.equalTo(0)
    }
  }


  // MARK: Configuring

  func configure(reactor: Reactor) {
    // DataSource
    self.tableView.rx.setDelegate(self).addDisposableTo(self.disposeBag)
    self.dataSource.configureCell = { _, tableView, indexPath, reactor in
      let cell = tableView.dequeue(Reusable.taskCell, for: indexPath)
      cell.configure(reactor: reactor)
      return cell
    }
    self.dataSource.canEditRowAtIndexPath = { _ in true }
    self.dataSource.canMoveRowAtIndexPath = { _ in true }

    let actions = [
      self.rx.viewDidLoad.map(Reactor.Action.refresh),
      self.editButtonItem.rx.tap.map(Reactor.Action.toggleEditing),
      self.tableView.rx.itemMoved.map(Reactor.Action.moveTask),
      self.tableView.rx.itemDeleted.map(Reactor.Action.deleteTask),
    ]
    Observable.from(actions)
      .merge()
      .bindTo(reactor.action)
      .addDisposableTo(self.disposeBag)

    reactor.state.map { $0.sections }
      .bindTo(self.tableView.rx.items(dataSource: self.dataSource))
      .addDisposableTo(self.disposeBag)

    reactor.state.map { $0.isEditing }
      .distinctUntilChanged()
      .subscribe(onNext: { [weak self] isEditing in
        guard let `self` = self else { return }
        self.navigationItem.leftBarButtonItem?.title = isEditing ? "Done" : "Edit"
        self.navigationItem.leftBarButtonItem?.style = isEditing ? .done : .plain
        self.tableView.setEditing(isEditing, animated: true)
      })
      .addDisposableTo(self.disposeBag)
  }

}


// MARK: - UITableViewDelegate

extension TaskListViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let reactor = self.dataSource[indexPath]
    return TaskCell.height(fits: tableView.width, reactor: reactor)
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }

//  tableview

}
