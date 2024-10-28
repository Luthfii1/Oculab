//
//  DummyJSON.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

class DummyJSON {
    let examinationCards = """
    [
        {
            "_id": "sampleId1",
            "goal": null,
            "preparationType": "SPS",
            "slideId": "slide1",
            "recordVideo": null,
            "WSI": null,
            "examinationDate": "2022-01-01T12:00:00Z",
            "FOV": null,
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "statusExamination": "INPROGRESS",
            "systemResult": null,
            "expertResult": null
        },
        {
            "_id": "sampleId2",
            "goal": null,
            "preparationType": "SP",
            "slideId": "slide2",
            "recordVideo": null,
            "WSI": null,
            "examinationDate": "2022-01-02T12:00:00Z",
            "FOV": null,
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "statusExamination": "INPROGRESS",
            "systemResult": null,
            "expertResult": null
        },
        {
            "_id": "sampleId3",
            "goal": null,
            "preparationType": "SP",
            "slideId": "slide3",
            "recordVideo": null,
            "WSI": null,
            "examinationDate": "2022-01-12T12:00:00Z",
            "FOV": null,
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "statusExamination": "FINISHED",
            "systemResult": null,
            "expertResult": null
        },
        {
            "_id": "sampleId4",
            "goal": null,
            "preparationType": "SPS",
            "slideId": "slide4",
            "recordVideo": null,
            "WSI": null,
            "examinationDate": "2022-01-12T12:00:00Z",
            "FOV": null,
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "statusExamination": "NEEDVALIDATION",
            "systemResult": null,
            "expertResult": null
        },
        {
            "_id": "sampleId5",
            "goal": null,
            "preparationType": "SP",
            "slideId": "slide5",
            "recordVideo": null,
            "WSI": null,
            "examinationDate": "2022-01-12T12:00:00Z",
            "FOV": null,
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "statusExamination": "NEEDVALIDATION",
            "systemResult": null,
            "expertResult": null
        }
    ]
    """.data(using: .utf8)!
}
