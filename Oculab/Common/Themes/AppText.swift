//
//  AppText.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: - Convenient Type Aliases (Shorter access)
typealias AppAction = AppText.Action
typealias AppState = AppText.State
typealias AppLabel = AppText.Label
typealias AppValue = AppText.Value
typealias AppPatient = AppText.PatientData
typealias AppMedical = AppText.Medical
typealias AppSearch = AppText.Search
typealias AppForm = AppText.Form
typealias AppNav = AppText.Navigation
typealias AppData = AppText.Data
typealias AppIcon = AppText.SystemIcon
typealias AppImage = AppText.AppIcon
typealias AppFeature = AppText.Feature

enum AppText {
    // MARK: - Core System Icons (Reusable across all modules)
    enum SystemIcon {
        static let back = "chevron.left"
        static let forward = "chevron.right"
        static let up = "chevron.up"
        static let down = "chevron.down"
        static let backCircle = "chevron.backward.circle"
        static let close = "xmark"
        static let add = "plus"
        static let edit = "pencil"
        static let delete = "trash"
        static let search = "magnifyingglass"
        static let settings = "gearshape"
        static let info = "info.circle"
        static let warning = "exclamationmark.triangle.fill"
        static let alert = "exclamationmark.circle.fill"
        static let success = "checkmark.circle.fill"
        static let error = "xmark.circle.fill"
        static let circleFill = "circle.fill"
        static let camera = "camera"
        static let cameraFill = "camera.fill"
        static let photo = "photo"
        static let document = "doc.text"
        static let documentFill = "doc.text.fill"
        static let share = "square.and.arrow.up"
        static let refresh = "arrow.counterclockwise"
        static let calendar = "calendar"
        static let ellipsis = "ellipsis"
        static let eye = "eye"
        static let eyeSlash = "eye.slash"
        static let faceId = "faceid"
        static let checkmark = "checkmark"
        static let personFill = "person.fill"
        static let arrowRight = "arrow.right"
        static let arrowForward = "arrow.forward"
        static let lock = "lock"
        static let lockCircleDotted = "lock.circle.dotted"
        static let lockShield = "lock.shield"
        static let doorRightHandOpen = "door.right.hand.open"
        static let docTextMagnifyingglass = "doc.text.magnifyingglass"
        static let paperplane = "paperplane"
        static let textBadgeCheckmark = "text.badge.checkmark"
        static let docOnDocFill = "doc.on.doc.fill"
        static let docBadgePlus = "doc.badge.plus"
        static let deleteLeftFill = "delete.left.fill"
        static let robot = "robot"
        static let rectangleStackFill = "rectangle.stack.fill"
        static let trayFullFill = "tray.full.fill"
        static let preparationSection = "list.number"
        static let rectangleSplit2x2Fill = "rectangle.split.2x2.fill"
        static let clockArrowCirclepath = "clock.arrow.circlepath"
        static let clockFill = "clock.fill"
        static let personCircle = "person.circle"
        static let squareAndPencil = "square.and.pencil"
        static let circle = "circle"
        static let largecircleFillCircle = "largecircle.fill.circle"
        static let buttonProgrammable = "button.programmable"
    }
    
    // MARK: - App Specific Icons
    enum AppIcon {
        static let logo = "logo"
        static let destroy = "Destroy"
        static let confirm = "Confirm"
        static let confirmLeave = "Confirm-Leave"
        static let contrast = "Contrast"
        static let brightness = "Brightness"
        static let comment = "Comment"
        static let addAccount = "AddAccount"
        static let phone = "phoneIcon"
        static let envelope = "envelopeIcon"
        static let line = "line"
        static let backWhite = "back_white"
        static let back = "back"
        static let success = "Success"
        static let robot = "robot"
        static let instruction = "Instruction"
        static let logoSplashScreen = "LogoSplashScreen"
        static let login = "LoginImage"
    }
    
    // MARK: - Universal Actions (Used across all modules)
    enum Action {
        static let ok = "common.ok".localized
        static let cancel = "common.cancel".localized
        static let save = "common.save".localized
        static let delete = "common.delete".localized
        static let edit = "common.edit".localized
        static let close = "common.close".localized
        static let next = "common.next".localized
        static let back = "common.back".localized
        static let done = "common.done".localized
        static let exit = "common.exit".localized
        static let settings = "common.settings".localized
        static let retry = "common.retry".localized
        static let refresh = "common.refresh".localized
        static let continueAct = "common.continue".localized
        static let skip = "common.skip".localized
        static let confirm = "common.confirm".localized
        static let search = "common.search".localized
        
        // Common button patterns
        static let saveChanges = "common.save_changes".localized
        static let saveData = "common.save_data".localized
        static let addNew = "common.add_new".localized
        static let editData = "common.edit_data".localized
        static let deleteData = "common.delete_data".localized
        
        // Dynamic functions for custom combinations
        static func save(_ itemType: String) -> String {
            return "common.save_item".localized(with: itemType)
        }
        
        static func add(_ itemType: String?) -> String {
            let item = itemType ?? ""
            return "common.add_item".localized(with: item)
        }
        
        static func edit(_ itemType: String) -> String {
            return "common.edit_item".localized(with: itemType)
        }
        
        static func delete(_ itemType: String) -> String {
            return "common.delete_item".localized(with: itemType)
        }
        
        static func view(_ itemType: String) -> String {
            return "common.view_item".localized(with: itemType)
        }
        
        static func backTo(_ destination: String) -> String {
            return "common.back_to".localized(with: destination)
        }
        
        static func startAction(_ actionType: String) -> String {
            return "common.start_action".localized(with: actionType)
        }
        
        static func create(_ itemType: String) -> String {
            return "common.create_item".localized(with: itemType)
        }
        
        static func disable(_ itemType: String) -> String {
            return "common.disable_item".localized(with: itemType)
        }
    }
    
    // MARK: - Universal States (Used across all modules)
    enum State {
        static let loading = "state.loading".localized
        static let empty = "state.empty".localized
        static let error = "state.error".localized
        static let success = "state.success".localized
        static let pending = "state.pending".localized
        static let notAvailable = "state.not_available".localized
        static let unknown = "state.unknown".localized
        static let completed = "state.completed".localized
        static let inProgress = "state.in_progress".localized
        
        // Dynamic status patterns
        static func loading(_ action: String) -> String {
            return "state.loading_action".localized(with: action)
        }
        
        static func success(_ action: String) -> String {
            return "state.success_action".localized(with: action)
        }
        
        static func failed(_ action: String) -> String {
            return "state.failed_action".localized(with: action)
        }
        
        static func noData(_ itemType: String) -> String {
            return "state.no_data".localized(with: itemType)
        }
        
        static func notDetermined(_ itemType: String) -> String {
            return "state.not_determined".localized(with: itemType)
        }
        
        static func successWith(_ action: String, _ itemType: String) -> String {
            return "state.success_with".localized(with: action, itemType)
        }
    }
    
    // MARK: - Universal Labels (Common field names)
    enum Label {
        static let name = "label.name".localized
        static let email = "label.email".localized
        static let password = "label.password".localized
        static let phone = "label.phone".localized
        static let address = "label.address".localized
        static let date = "label.date".localized
        static let time = "label.time".localized
        static let notes = "label.notes".localized
        static let description = "label.description".localized
        static let title = "label.title".localized
        static let type = "label.type".localized
        static let status = "label.status".localized
        static let result = "label.result".localized
        static let category = "label.category".localized
        static let role = "label.role".localized
    }
    
    // MARK: - Common Values
    enum Value {
        static let empty = ""
        static let defaultStrike = "-"
        static let bullet = "•"
        static let percentage = "%"
        static let required = "*"
        static let unknownError = "common.unknown_error".localized
        static let unknownMessage = "common.unknown_message".localized
    }
    
    // MARK: - Patient Data (Reusable across modules)
    enum PatientData {
        static let name = "patient.name".localized
        static let nik = "patient.nik".localized
        static let dateOfBirth = "patient.dob".localized
        static let gender = "patient.gender".localized
        static let bpjsNumber = "patient.bpjs".localized
        static let age = "patient.age".localized
        static let ageSuffix = "patient.age_suffix".localized
        
        enum Gender {
            static let male = "patient.gender.male".localized
            static let female = "patient.gender.female".localized
            static let other = "patient.gender.other".localized
        }
        
        enum Placeholder {
            static let name = "patient.placeholder.name".localized
            static let nik = "patient.placeholder.nik".localized
            static let bpjs = "patient.placeholder.bpjs".localized
            static let selectDate = "patient.placeholder.select_date".localized
        }
    }
    
    // MARK: - Medical Terms (Reusable across examination modules)
    enum Medical {
        static let patient = "medical.patient".localized
        
        enum BTA {
            static let negative = "medical.bta.negative".localized
            static let scanty = "medical.bta.scanty".localized
            static let positive1 = "medical.bta.positive1".localized
            static let positive2 = "medical.bta.positive2".localized
            static let positive3 = "medical.bta.positive3".localized
            
            enum Description {
                static let negative = "medical.bta.desc.negative".localized
                static let scanty = "medical.bta.desc.scanty".localized
                static let positive1 = "medical.bta.desc.positive1".localized
                static let positive2 = "medical.bta.desc.positive2".localized
                static let positive3 = "medical.bta.desc.positive3".localized
            }
        }
        
        enum Examination {
            static let purpose = "medical.exam.purpose".localized
            static let result = "medical.exam.result".localized
            static let interpretation = "medical.exam.interpretation".localized
            static let staffInterpretation = "medical.exam.staff_interpretation".localized
            static let systemInterpretation = "medical.exam.system_interpretation".localized
            static let bacteriaCount = "medical.exam.bacteria_count".localized
            static let slideId = "medical.exam.slide_id".localized
            static let examinationId = "medical.exam.examination_id".localized
            static let specimenType = "medical.exam.specimen_type".localized
            static let specimenInfo = "medical.exam.specimen_info".localized
            static let microscopicInterpretation = "medical.exam.microscopic_interpretation".localized
            static let bacteriaCountSuffix = "medical.exam.bacteria_suffix".localized
            static let confidenceLevel = "medical.exam.confidence_level".localized
            static let goalScreening = "medical.exam.goal_screening".localized
            static let goalFollowUp = "medical.exam.goal_followup".localized
            static let preparationTypeAnytime = "medical.exam.preparation_anytime".localized
            static let preparationTypeMorning = "medical.exam.preparation_morning".localized
        }
        
        enum Confidence {
            static let perfect = "medical.confidence.perfect".localized
            static let high = "medical.confidence.high".localized
            static let medium = "medical.confidence.medium".localized
            static let low = "medical.confidence.low".localized
            static let veryLow = "medical.confidence.very_low".localized
            static let unpredicted = "medical.confidence.unpredicted".localized
        }
    }
    
    // MARK: - Search & Filter (Reusable components)
    enum Search {
        static let search = "search.search".localized
        static let placeholder = "search.placeholder".localized
        static let noResults = "search.no_results".localized
        static let clearSearch = "search.clear".localized
        static let searching = "search.searching".localized
        
        enum Patient {
            static let placeholder = "search.patient.placeholder".localized
        }
        
        enum Account {
            static let placeholder = "search.account.placeholder".localized
        }
        
        static func noResults(_ searchTerm: String) -> String {
            return "search.no_results_for".localized(with: searchTerm)
        }
        
        static func resultFor(_ itemType: String) -> String {
            return "search.result_for".localized(with: itemType)
        }
    }
    
    // MARK: - Forms (Reusable form elements)
    enum Form {
        static let optional = "form.optional".localized
        static let selectOption = "form.select_option".localized
        static let enterValue = "form.enter_value".localized
        static let disable = "form.disable".localized
        
        enum Validation {
            static let required = "form.validation.required".localized
            static let invalid = "form.validation.invalid".localized
            static let tooShort = "form.validation.too_short".localized
            static let tooLong = "form.validation.too_long".localized
        }
        
        static func placeholder(_ fieldName: String) -> String {
            return "form.placeholder".localized(with: fieldName)
        }
        
        static func select(_ itemType: String) -> String {
            return "form.select".localized(with: itemType)
        }
        
        static func search(_ itemType: String) -> String {
            return "form.search".localized(with: itemType)
        }
    }
    
    // MARK: - Navigation (Reusable navigation items)
    enum Navigation {
        static let profile = "nav.profile".localized
        static let history = "nav.history".localized
        static let examination = "nav.examination".localized
        static let patients = "nav.patients".localized
        static let settings = "nav.settings".localized
        static let accountManagement = "nav.account_management".localized
    }
    
    // MARK: - Common Data Patterns
    enum Data {
        static func count(_ number: Int, _ itemType: String) -> String {
            return "data.count".localized(with: number, itemType)
        }
        
        static func fromTo(_ current: Int, _ total: Int, _ itemType: String) -> String {
            return "data.from_to".localized(with: current, total, itemType)
        }
        
        static func imageCount(_ current: Int, _ total: Int) -> String {
            return "data.image_count".localized(with: current, total)
        }
        
        static func albumTitle(_ itemName: String) -> String {
            return "data.album_title".localized(with: itemName)
        }
        
        static func resultTitle(_ itemName: String, _ slideNumber: Int) -> String {
            return "data.result_title".localized(with: itemName, slideNumber)
        }
        
        static func slideTitle(_ slideNumber: Int) -> String {
            return "data.slide_title".localized(with: slideNumber)
        }
        
        static func slideIdTitle(_ slideNumber: Int) -> String {
            return "data.slide_id_title".localized(with: slideNumber)
        }

        static func slideIdPlaceholder(_ slideNumber: String) -> String {
            return "data.slide_id_placeholder".localized(with: slideNumber)
        }
        
        static func slideTypeTitle(_ slideNumber: Int) -> String {
            return "data.slide_type_title".localized(with: slideNumber)
        }
        
        static func withPrefix(_ prefix: String, _ content: String) -> String {
            return "data.with_prefix".localized(with: prefix, content)
        }
        
        static func makeSentence<T>(_ words: [T]) -> String {
            guard !words.isEmpty else {
                return ""
            }
            
            var sentence = String(describing: words[0])
            
            for word in words.dropFirst() {
                sentence += " \(String(describing: word))"
            }
            
            return sentence
        }
    }
    
    enum Feature {
        static let radioButton = "feature.radio_button".localized
    }
}
