//
//  FlickerPhotosVC.swift
//  FlickrSearch
//
//  Created by Mac on 9/5/17.
//  Copyright © 2017 Azhar. All rights reserved.
//

import UIKit



class FlickerPhotosVC: UIViewController {

    fileprivate let reuseIdentifier = "FlickerCell"
    fileprivate let reuseHeaderIdentifier = "FlickrPhotoHeaderView"
    fileprivate let sectionInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    fileprivate let itemsPerRow : CGFloat = 3
    
    fileprivate var selectedPhotos = [FlickrPhoto]()
    fileprivate let shareTextLabel = UILabel()
    
    fileprivate var searches = [FlickrSearchResults]()
    fileprivate let flickr = Flickr()
    
    var largeIndexPath: IndexPath? {
        didSet{
            var indexPaths = [IndexPath]()
            if let largeIndexPath = largeIndexPath{
                indexPaths.append(largeIndexPath)
            }
            if let oldValue = oldValue{
                indexPaths.append(oldValue)
            }
            //3
            collectionView.performBatchUpdates({ 
                self.collectionView.reloadItems(at: indexPaths)
            }) { (completed) in
                if let largeIndexPath = self.largeIndexPath{
                    self.collectionView.scrollToItem(at: largeIndexPath, at: .centeredVertically, animated: true)
                }
            }
        }
    }
    
    var sharing: Bool = false{
        didSet{
            collectionView.allowsMultipleSelection = sharing
            collectionView.selectItem(at: nil, animated: true, scrollPosition: UICollectionViewScrollPosition())
            selectedPhotos.removeAll(keepingCapacity: false)
            
            guard let shareButton = self.navigationItem.rightBarButtonItems?.first else {
                return
            }
            guard sharing else {
                navigationItem.setLeftBarButtonItems([shareButton], animated: true)
                return
            }
            if let _ = largeIndexPath{
                largeIndexPath = nil
            }
            updateSharedPhotoCount()
            let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
            navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
            
        }
    }
    
    lazy var barButtonItem: UIBarButtonItem = {
        //let bi = UIBarButtonItem(title: "done", style: .plain, target: self, action: #selector(share(_:)))
        let bi = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(share(_:)))
        bi.style = UIBarButtonItemStyle.plain
        return bi
    }()
    
    lazy var textField : UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Search Flickr Photos"
        tf.textAlignment = .center
        tf.backgroundColor = UIColor.white
        tf.borderStyle = .roundedRect
        tf.delegate = self
        return tf
    } ()
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.white
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    private func setupViews(){
        self.view.backgroundColor = UIColor.white
        self.title = "Flicker Search"
        self.view.addSubview(textField)
        
        textField.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 8).isActive = true
        textField.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -8).isActive = true
        textField.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor , constant: 8).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        self.view.addSubview(collectionView)
        collectionView.register(FlickerPhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(FlickerPhotoHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: reuseHeaderIdentifier)
        collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: self.textField.bottomAnchor).isActive = true
        
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = barButtonItem
        
            }
    
    func share(_ sender: UIBarButtonItem){
        print("share button pressed")
    }
}



// MARK:- Private


private extension FlickerPhotosVC{
    func photoForIndexPath(indexPath: IndexPath) -> FlickrPhoto{
        return searches[indexPath.section].searchResults[indexPath.row]
    }
    func updateSharedPhotoCount(){
        shareTextLabel.textColor = themeColor
        shareTextLabel.text = "\(selectedPhotos.count) photos Selected"
        shareTextLabel.sizeToFit()
    }
}
extension FlickerPhotosVC : UICollectionViewDelegate , UICollectionViewDataSource{
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickerPhotoCell
        let flickerPhoto = photoForIndexPath(indexPath: indexPath)
        cell.activityIndicator.stopAnimating()
        
        guard indexPath == largeIndexPath else {
            cell.imageView.image = flickerPhoto.thumbnail
            return cell
        }
        guard flickerPhoto.largeImage == nil else {
            cell.imageView.image = flickerPhoto.largeImage
            return cell
        }
        cell.imageView.image = flickerPhoto.thumbnail
        cell.activityIndicator.startAnimating()
        
        flickerPhoto.loadLargeImage { (loadedFlickerPhoto, error) in
            cell.activityIndicator.stopAnimating()
            
            guard loadedFlickerPhoto.largeImage != nil && error == nil else {
                return
            }
            if let cell = collectionView.cellForItem(at: indexPath) as? FlickerPhotoCell,
            indexPath == self.largeIndexPath {
                cell.imageView.image = loadedFlickerPhoto.largeImage
            }
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseHeaderIdentifier, for: indexPath) as! FlickerPhotoHeaderView
            headerView.label.text = searches[indexPath.section].searchTerm
            headerView.backgroundColor = UIColor.lightGray
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
}

extension FlickerPhotosVC: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath == largeIndexPath{
            let flickerPhoto = photoForIndexPath(indexPath: indexPath)
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.bottom)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickerPhoto.sizeToFillWidthOfSize(size)
        }
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 30)
    }
}
//MARK:- CollectionViewDelegate
extension FlickerPhotosVC{
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        largeIndexPath = largeIndexPath == indexPath ? nil : indexPath
        return false
    }
}

extension FlickerPhotosVC: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        flickr.searchFlickrForTerm(textField.text!) { (results, error) in
            activityIndicator.removeFromSuperview()
            if let error = error {
                print("Error Searching : \(error)")
            }
            if let results = results {
                print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                self.searches.insert(results, at: 0)
                self.collectionView.reloadData()
            }
            
        }
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}
class FlickerPhotoCell: BaseCell  {
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = UIColor.white
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    let activityIndicator : UIActivityIndicatorView = {
        let av = UIActivityIndicatorView()
        av.translatesAutoresizingMaskIntoConstraints = false
        return av
    }()
    
    override var isSelected: Bool{
        didSet {
            imageView.layer.borderWidth = isSelected ? 10 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.borderColor = themeColor.cgColor
        isSelected = false
    }
    
    override func setupViews() {
    //MARK:- ImageView
        
        self.addSubview(imageView)
        imageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        
        self.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
    }
    
}
class FlickerPhotoHeaderView: BaseReusableView{
    
    let label: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = UIColor.black
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.sizeToFit()
        return lbl
    }()
    
    override func setupViews() {
        self.addSubview(label)
        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
}





class BaseCell : UICollectionViewCell{
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    fileprivate func setupViews(){
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BaseReusableView: UICollectionReusableView{
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    fileprivate func setupViews(){
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}








