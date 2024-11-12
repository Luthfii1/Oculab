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

    let examinationDetail = """
    {
        "data": {
            "FOV": [],
            "_id": "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2",
            "goal": "SCREENING",
            "preparationType": "SPS",
            "slideId": "slide123",
            "examinationDate": "2024-10-30T08:00:00.000Z",
            "imagePreview": "http://example.com/image/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "statusExamination": "NOTSTARTED",
            "PIC": {
                "_id": "d3f12345-6789-4bc8-91e6-bb3b67f8cabc",
                "name": "Dr. Luthfi Munir",
                "role": "LAB",
                "email": "luthfi@example.com"
            },
            "examinationPlanDate": "2024-10-30T09:00:00.000Z"
    }
    """.data(using: .utf8)!

    let examinationResult = """
    {
        "message": "Examination data received successfully",
        "data": {
            "FOV": [],
            "_id": "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2",
            "goal": "SCREENING",
            "preparationType": "SPS",
            "slideId": "slide123",
            "examinationDate": "2024-10-30T08:00:00.000Z",
            "imagePreview": "http://example.com/image/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
            "statusExamination": "NOTSTARTED",
            "systemResult": {
                "_id": "", 
                "systemGrading": "NEGATIVE", 
                "confidenceLevelAggregated": 98.0, 
                "systemBacteriaTotalCount: 0    
            },
            "PIC": {
                "_id": "d3f12345-6789-4bc8-91e6-bb3b67f8cabc",
                "name": "Dr. Luthfi Munir",
                "role": "LAB",
                "email": "luthfi@example.com",
                "password": "elbachul"
            },
            "examinationPlanDate": "2024-10-30T09:00:00.000Z",
            "DPJP": {
                "_id": "b2c34567-8901-5efe-92f7-dd4e89a9dabc",
                "name": "Michael Thompson",
                "role": "ADMIN",
                "email": "michael.thompson@example.com"
            }
        }
    }
    """
}

let errorJSON = """
{
    "status": "error",
    "code": 400,
    "message": "Patient not found",
    "data": {
        "errorType": "VALIDATION_ERROR",
        "description": "No patient found with the provided patient ID."
    }
}
""".data(using: .utf8)!
