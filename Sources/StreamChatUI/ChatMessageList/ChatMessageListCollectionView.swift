//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Protocol that adds delegate methods specific for `ChatMessageListCollectionView`
public protocol ChatMessageListCollectionViewDataSource: UICollectionViewDataSource {
    /// Get date for item at given indexPath
    /// - Parameters:
    ///   - collectionView: CollectionView requesting date
    ///   - indexPath: IndexPath that should be used to get date
    func collectionView(_ collectionView: UICollectionView, scrollOverlayTextForItemAt indexPath: IndexPath) -> String?
}

/// The collection view that provides convenient API for dequeuing `_ChatMessageCollectionViewCell` instances
/// with the provided content view type and layout options.
open class ChatMessageListCollectionView<ExtraData: ExtraDataTypes>: UICollectionView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()

    /// View used to display date of currently displayed messages
    open lazy var scrollOverlayView: ChatMessageListScrollOverlayView = {
        let scrollOverlayView = components.messageListScrollOverlayView.init()
        scrollOverlayView.isHidden = true
        return scrollOverlayView.withoutAutoresizingMaskConstraints
    }()
    
    private var isInitialized = false
    
    /// Usual `dataSource` method cast to `ChatMessageListCollectionViewDataSource`
    private var chatDataSource: ChatMessageListCollectionViewDataSource? {
        dataSource as? ChatMessageListCollectionViewDataSource
    }

    private var contentSizeObservation: NSKeyValueObservation?
    private var contentOffsetObservation: NSKeyValueObservation?
    
//    // The content inset set by the user. It's not used directly but it's assigned to super
//    // in `layoutSubviews()`. We adjust the top inset for situations when the content size
//    // is smaller than the bounds to keep the content to the bottom.
//    private var _contentInset: UIEdgeInsets = .zero
//
//    override open var contentInset: UIEdgeInsets {
//        set { _contentInset = newValue }
//        get { _contentInset }
//    }
    
    // In some cases updates coming one by one might require scrolling to bottom.
    //
    // Scheduling the action and canceling the previous one ensures the scroll to bottom
    // is done only once.
    //
    // Having a delay gives layout a chance to calculate the correct size for bottom cells
    // so they are fully visible when scroll to bottom happens.
    private var scrollToBottomAction: DispatchWorkItem? {
        didSet {
            oldValue?.cancel()
            if let action = scrollToBottomAction {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + .milliseconds(200),
                    execute: action
                )
            }
        }
    }

    public required init(layout: ChatMessageListCollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true

        insetsLayoutMarginsFromSafeArea = false

        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }
    
    open func setUp() {
        contentSizeObservation = observe(\.contentSize) { _, _ in
//            print("""
//            💡 CONTENT SIZE: \(cv.contentSize)
//            """)
        }

        // Setup `contentOffset` observation so `delegate` is free for anyone that wants to use it
        contentOffsetObservation = observe(\.contentOffset) { cv, _ in
//            print("""
//            💡 CONTENT OFFSET: \(cv.contentOffset)
//            """)
            
            /// To display correct date we use bottom edge of `dateView` (we use `cv.layoutMargins.top` for both vertical offsets of `dateView`
            let dateViewRefPoint = CGPoint(
                x: cv.scrollOverlayView.center.x,
                y: cv.scrollOverlayView.frame.maxY + cv.layoutMargins.top
            )
            let refPoint = cv.convert(dateViewRefPoint, to: cv)
            // To get correct indexPath, we cannot use `cv.indexPathForItem(at:)` as it breaks collectionView layout
            // and all cells have fix 72pt width, so we search which visible cell contains our `refPoint`
            // and then search for its indexPath
            /// Cell that contains our `refPoint` if any
            let cell = cv.visibleCells.first(where: { $0.frame.contains(refPoint) })

            // If we cannot find any indexPath for `cell` we try to use max visible indexPath (we have bottom to top) layout
            guard let indexPath = cell.flatMap(cv.indexPath) ?? cv.indexPathsForVisibleItems.max() else { return }
            
            let overlayText = cv.chatDataSource?.collectionView(cv, scrollOverlayTextForItemAt: indexPath)
            
            // As cells can overlay our `dateView` we need to keep it above them
            cv.bringSubviewToFront(cv.scrollOverlayView)
            
            // If we have no date we have no reason to display `dateView`
            cv.scrollOverlayView.isHidden = (overlayText ?? "").isEmpty
            cv.scrollOverlayView.content = overlayText
            
            // Apple's naming is quite weird as actually this property should rather be named `isScrolling`
            // as it stays true when user stops dragging and scrollView is decelerating and becomes false
            // when scrollView stops decelerating
            //
            // But this case doesn't cover situation when user drags scrollView to a certain `contentOffset`
            // leaves the finger there for a while and then just lifts it, it doesn't change `contentOffset`
            // so this handler is not called, this is handled by `scrollStateChanged`
            // that reacts on `panGestureRecognizer` states and can handle this case properly
            if !cv.isDragging {
                cv.setOverlayViewAlpha(0)
            }
        }
        
        panGestureRecognizer.addTarget(self, action: #selector(scrollStateChanged))
    }
    
    @objc
    open func scrollStateChanged(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            setOverlayViewAlpha(1)
        case .ended, .cancelled, .failed:
            // This case handles situation when user pans to certain `contentOffset`, leaves the finger there
            // and then lifts it without `contentOffset` change, so `scrollView` will not decelerate, if it does,
            // it is handled by `contentOffset` observation
            if !isDecelerating {
                setOverlayViewAlpha(0)
            }
        default: break
        }
    }
    
    open func setUpLayout() {
        addSubview(scrollOverlayView)
        
        NSLayoutConstraint.activate([
            scrollOverlayView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            scrollOverlayView.centerXAnchor.pin(equalTo: layoutMarginsGuide.centerXAnchor),
            scrollOverlayView.leadingAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
            scrollOverlayView.trailingAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    open func setUpAppearance() {
        // Nothing to do
    }
    
    open func updateContent() {
        // Nothing to do
    }

//    override open func layoutSubviews() {
//        var adjustedContentInset = _contentInset
//
//        // If the content size is smaller than bounds, we have to adjust the top inset
//        // to make sure the content stays pinned to the bottom.
//        if contentSize.height < bounds.height {
//            adjustedContentInset.top = max(bounds.height - contentSize.height - contentInset.bottom, _contentInset.top)
//        }
//
//        if super.contentInset != adjustedContentInset {
//            super.contentInset = adjustedContentInset
//        }
//
//        super.layoutSubviews()
//    }
    
    /// Dequeues the message cell. Registers the cell for received combination of `contentViewClass + layoutOptions`
    /// if needed.
    /// - Parameters:
    ///   - contentViewClass: The type of content view the cell will be displaying.
    ///   - layoutOptions: The option set describing content view layout.
    ///   - indexPath: The cell index path.
    /// - Returns: The instance of `_ChatMessageCollectionViewCell<ExtraData>` set up with the
    /// provided `contentViewClass` and `layoutOptions`
    open func dequeueReusableCell(
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> _ChatMessageCollectionViewCell<ExtraData> {
        let reuseIdentifier =
            "\(_ChatMessageCollectionViewCell<ExtraData>.reuseId)_" + "\(layoutOptions.rawValue)_" +
            "\(contentViewClass)_" + String(describing: attachmentViewInjectorType)

        // There is no public API to find out
        // if the given `identifier` is registered.
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)
            
            register(_ChatMessageCollectionViewCell<ExtraData>.self, forCellWithReuseIdentifier: reuseIdentifier)
        }
            
        let cell = dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as! _ChatMessageCollectionViewCell<ExtraData>
        cell.setMessageContentIfNeeded(
            contentViewClass: contentViewClass,
            attachmentViewInjectorType: attachmentViewInjectorType,
            options: layoutOptions
        )
        cell.messageContentView?.indexPath = { [weak cell, weak self] in
            guard let cell = cell else { return nil }
            return self?.indexPath(for: cell)
        }

        return cell
    }
    
    /// Updates the collection view data with given `changes`.
    open func updateMessages(
        with changes: [ListChange<_ChatMessage<ExtraData>>],
        isAnimated: Bool = false,
        scrollBehavior: ScrollBehavior? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
//        setNeedsLayout()
//        layoutIfNeeded()

        // Before committing the change the scroll behavior needs opportunity to capture
        // the pre-update state
        var scrollBehavior = scrollBehavior
        scrollBehavior?.preUpdate(self)

        Animate(isAnimated: scrollBehavior?.areUpdatesAnimated ?? true) {
            self.performBatchUpdates {
                for change in changes {
                    switch change {
                    case let .insert(_, index):
                        self.insertItems(at: [index])
                    case let .move(_, fromIndex, toIndex):
                        self.moveItem(at: fromIndex, to: toIndex)
                    case let .remove(_, index):
                        self.deleteItems(at: [index])
                    case let .update(_, index):
                        self.reloadItems(at: [index])
                    }
                }
            } completion: { flag in
                // If a new message was inserted or deleted, reload the previous message
                // to give it chance to update its appearance in case it's now end of a group.
                let indexPaths = self.indexPathsToReloadAfterBatchUpdates(with: changes)
                if indexPaths.isEmpty == false {
                    self.reloadItems(at: indexPaths)
                }

                scrollBehavior?.postUpdate(self)

                completion?(flag)
            }
        }
    }
    
    private func indexPathsToReloadAfterBatchUpdates(
        with changes: [ListChange<_ChatMessage<ExtraData>>]
    ) -> [IndexPath] {
        changes.compactMap {
            switch $0 {
            // Check if the latest message was inserted
            case .insert(_, IndexPath(row: 0, section: 0)):
                guard numberOfItems(inSection: 0) > 1 else { return nil }
                
                // Reload the second-to latests message
                return .init(item: 1, section: 0)
            // Check if the message was deleted
            case let .remove(_, indexPath):
                guard numberOfItems(inSection: 0) > indexPath.item else { return nil }
                
                // Reload the previous message which is now at deleted message positon
                return indexPath
            default:
                return nil
            }
        }
    }
    
    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        // our collection is flipped, so (0; 0) item is most recent one
        scrollToItem(at: IndexPath(item: 0, section: 0), at: .bottom, animated: animated)
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setUpAppearance()
        updateContent()
        
        if traitCollection.preferredContentSizeCategory == previousTraitCollection?.preferredContentSizeCategory {
            return
        }
        
        collectionViewLayout.invalidateLayout()
    }
    
    open func setOverlayViewAlpha(_ alpha: CGFloat, animated: Bool = true) {
        Animate(isAnimated: animated) { [scrollOverlayView] in
            scrollOverlayView.alpha = alpha
        }
    }

    /// A Boolean that returns true if the bottom cell is fully visible.
    /// Which is also means that the collection view is fully scrolled to the boom.
    open var isLastCellFullyVisible: Bool {
        if numberOfItems(inSection: 0) == 0 { return true }
        let lastIndexPath = IndexPath(item: 0, section: 0)

        guard let attributes = collectionViewLayout.layoutAttributesForItem(at: lastIndexPath) else { return false }
        return bounds.contains(attributes.frame)
    }

    /// A Boolean that returns true if the last cell is visible, but can be just partially visible.
    open var isLastCellVisible: Bool {
        let lastIndexPath = IndexPath(item: 0, section: 0)
        return indexPathsForVisibleItems.contains(lastIndexPath)
    }
}
