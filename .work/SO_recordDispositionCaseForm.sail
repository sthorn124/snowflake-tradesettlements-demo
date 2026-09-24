a!formLayout(
  titleBar: "Record Disposition",
  contents: {
    a!textField(label: "Case", value: "SO-" & ri!caseId, readOnly: true),
    a!dropdownField(
      label: "Disposition",
      instructions: "How the settlement risk cleared. Codes only.",
      placeholder: "Select a disposition",
      choiceLabels: cons!SO_DISPOSITION_CODES,
      choiceValues: cons!SO_DISPOSITION_CODES,
      required: true,
      value: ri!disposition,
      saveInto: ri!disposition
    ),
    a!paragraphField(
      label: "Resolution note (optional)",
      instructions: "Free text is recorded as a case comment, never on the case itself.",
      height: "SHORT",
      value: ri!resolutionNote,
      saveInto: ri!resolutionNote
    )
  },
  buttons: a!buttonLayout(
    primaryButtons: a!buttonWidget(label: "Record Disposition", submit: true, style: "SOLID")
  )
)
