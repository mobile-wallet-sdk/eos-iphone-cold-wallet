//
//  PageViewController.swift
//  EOS Cold Wallet
//

import UIKit

class PageViewController: UIPageViewController {
    
    var pageData =  [] as [String]
    var label : UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        label = UILabel(frame: CGRect(x: 0, y: view.bounds.height * 0.5 - 30 - 48, width: view.bounds.width, height: 60))
        label.text = "No EOS accounts installed.\nAdd one or more accounts."
        label.textAlignment = .center
        label.numberOfLines = 2
        self.view.addSubview(label)
        
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = .lightGray
        appearance.currentPageIndicatorTintColor = .green
        showAccounts()
        
    }
    
    func showAccounts() {
        if pageData.count > 0 {
            label.text = nil
            self.delegate = nil
            self.dataSource = nil
            if self.viewControllers?.count  == 0 {
                let accountViewController = AccountViewController(nibName: "AccountViewController", bundle: nil)
                accountViewController.dataObject = self.pageData[0]
                let viewControllers = [accountViewController]
                self.setViewControllers(viewControllers, direction: .forward, animated: false, completion: {done in })
            }
            self.delegate = self
            self.dataSource = self
        }
    }
    
    func viewControllerAtIndex(_ index: Int) -> AccountViewController? {
        // Return the data view controller for the given index.
        if (self.pageData.count == 0) || (index >= self.pageData.count) {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        let accountViewController = AccountViewController(nibName: "AccountViewController", bundle: nil)
        
        accountViewController.dataObject = self.pageData[index]
        return accountViewController
    }
    
    func indexOfViewController(_ viewController: AccountViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        return pageData.index(of: viewController.dataObject) ?? NSNotFound
    }
}

extension PageViewController: UIPageViewControllerDelegate {
    /*
     var modelController: ModelController {
     // Return the model controller object, creating it if necessary.
     // In more complex implementations, the model controller may be passed to the view controller.
     if _modelController == nil {
     _modelController = ModelController()
     }
     return _modelController!
     }
     
     var _modelController: ModelController? = nil
     */
    // MARK: - UIPageViewController delegate methods
    
    
    
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        if (orientation == .portrait) || (orientation == .portraitUpsideDown) || (UIDevice.current.userInterfaceIdiom == .phone) {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewController.SpineLocation.mid' in landscape orientation sets the doubleSided property to true, so set it to false here.
            let currentViewController = self.viewControllers![0]
            let viewControllers = [currentViewController]
            self.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
            
            self.isDoubleSided = false
            return .min
        }
        
        // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
        let currentViewController = self.viewControllers![0] as! AccountViewController
        var viewControllers: [UIViewController]
        
        let indexOfCurrentViewController = self.indexOfViewController(currentViewController)
        if (indexOfCurrentViewController == 0) || (indexOfCurrentViewController % 2 == 0) {
            let nextViewController = self.pageViewController(self, viewControllerAfter: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            let previousViewController = self.pageViewController(self, viewControllerBefore: currentViewController)
            viewControllers = [previousViewController!, currentViewController]
        }
        self.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
        return .mid
    }
    
    
}

extension PageViewController: UIPageViewControllerDataSource {
    
    
    // MARK: - Page View Controller Data Source
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! AccountViewController)
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index -= 1
        return self.viewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! AccountViewController)
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        if index == self.pageData.count {
            return nil
        }

        return self.viewControllerAtIndex(index)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        print("presentationCount")
        return pageData.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        print("presentationIndex")
        let currentViewController = self.viewControllers![0]
        let indexOfCurrentViewController = self.indexOfViewController(currentViewController as! AccountViewController)
        return indexOfCurrentViewController
    }
}

