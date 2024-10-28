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
            "examinationId": "sampleId1",
            "statusExamination": "INPROGRESS",
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "timestamp": "2022-01-01T12:00:00Z",
            "slideId": "slide1"
        },
        {
            "examinationId": "sampleId2",
            "statusExamination": "INPROGRESS",
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "timestamp": "2022-01-02T12:00:00Z",
            "slideId": "slide2"
        },
        {
            "examinationId": "sampleId3",
            "statusExamination": "FINISHED",
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "timestamp": "2022-01-12T12:00:00Z",
            "slideId": "slide3"
        },
        {
            "examinationId": "sampleId4",
            "statusExamination": "NEEDVALIDATION",
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "timestamp": "2022-01-12T12:00:00Z",
            "slideId": "slide4"
        },
        {
            "examinationId": "sampleId5",
            "statusExamination": "NEEDVALIDATION",
            "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "timestamp": "2022-01-12T12:00:00Z",
            "slideId": "slide5"
        },
    ]
    """.data(using: .utf8)!
}
