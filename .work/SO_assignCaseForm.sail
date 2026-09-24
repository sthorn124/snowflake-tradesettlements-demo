a!formLayout(
  titleBar: "Assign Case",
  contents: {
    a!textField(label: "Case", value: "SO-" & ri!caseId, readOnly: true),
    a!pickerFieldUsers(
      label: "Assign to",
      instructions: "Only members of SO Analysts are suggested.",
      groupFilter: cons!SO_ANALYSTS_GROUP,
      maxSelections: 1,
      required: true,
      value: ri!assignee,
      saveInto: a!save(ri!assignee, index(save!value, 1, null))
    )
  },
  buttons: a!buttonLayout(
    primaryButtons: a!buttonWidget(label: "Assign", submit: true, style: "SOLID")
  )
)
