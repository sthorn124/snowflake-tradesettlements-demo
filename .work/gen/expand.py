#!/usr/bin/env python3
"""Expand short record references in a SAIL template into UUID-qualified ones.

  @{C}          -> 'recordType!{uuid}SO Settlement Case'
  @{C.status}   -> 'recordType!{uuid}SO Settlement Case.fields.{uuid}status'
  @{C>trade}    -> 'recordType!{uuid}SO Settlement Case.relationships.{uuid}trade'
  @{C>trade.desk} -> ...relationships.{uuid}trade.fields.{uuid}desk  (field of the related type)

Usage: expand.py <template> <output>.  Every UUID below was read from NY
(listRecordTypeFields / the deployed sources in .work) on 2026-11-12; none is invented.
An unknown token stops the run.
"""
import re, sys

RT = {
 "C": ("09405a10-06c7-4368-9d5e-41a148dffd15", "SO Settlement Case"),
 "M": ("c8cdbb02-1f27-4a90-933b-752f65b0f617", "SO Case Comment"),
 "E": ("eede988b-5576-4daa-a49c-fa962d90b16b", "SO Settlement Case Event History"),
 "P": ("b1967741-7f64-4259-a3af-ef2c6ea2e3bf", "SO Trade Predictions"),
 "T": ("8539c3b7-b402-4ba9-b5a0-e8c09a4980bd", "SO Trade"),
 "R": ("c48c9eb9-96e3-4642-b9c5-63c67b6e023a", "SO Demo Run"),
}
F = {
 "C": {"caseID":"4712df58-1d47-4398-b6f8-16d0f00531b3","tradeID":"e030ef7d-9626-47f2-90ca-fe586a435e6f",
       "sessionID":"1f2150e5-7908-447c-a9a7-0483983c6693","status":"b45a436e-95b4-4c9e-9808-65e017cb446b",
       "failReason":"61aca3bf-502f-41af-8996-e91de5d1b8ad","desk":"0653bdd6-0407-4cb1-a790-737cd07bef85",
       "cutoffTs":"8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad","proposedRemediation":"e88be2f5-7e27-4912-b941-278f50414fc7",
       "confidenceScore":"fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1","disposition":"c01cfb58-c4ed-4c25-82b2-d819b8bc8952",
       "resolvedOn":"a0a31026-e28d-4526-9c51-19b314a2fb33","createdOn":"10200e99-176e-44ce-a5dc-3c5c45847da5",
       "modifiedOn":"4ac3036c-ab51-4940-a5d5-363e4f2a8a09","assignee":"9b25abd4-5dde-4c5b-805d-b9968401cf9c"},
 "M": {"id":"fe1abf25-394d-44ad-a3d6-3903b1f3012c","caseId":"387260a3-561d-4cd3-9df7-d65a5cc775b6",
       "commentText":"2bb72559-6a2b-4624-b156-efc8237287ce","author":"ffa2f4eb-64b5-4a09-9f05-85fcd3f24d04",
       "createdOn":"4143f703-c044-40d9-a2fd-927d6a67795d"},
 "E": {"id":"6a72c7d1-2c74-4a71-a21d-7c58c0b2e1f8","timestamp":"2997cf09-138c-489d-a6ff-221de2e77243",
       "user":"c4acbfe1-23ab-4f68-9874-464b794d360b","eventTypeId":"4b704e07-732c-4152-9906-ee8107cb8c1b",
       "automationTypeId":"523e83ec-1a63-42a5-a5c0-e9bb3f76d085","comment":"6862ba51-9181-470c-8798-9bfd1cabc8bb",
       "recordId":"6c3a39d8-6dc6-425d-ab58-1d72fb487426"},
 "P": {"scoredAt":"1ae3b327-c800-4114-bcf0-4c45fca5dc1e","riskTier":"62c6c878-1193-4cdc-848a-b073854bb077",
       "failProbability":"ae03e55e-3c7b-4d4c-9000-5ec053f552a6","tradeId":"ba723c14-124b-48ff-ab51-02bf948242f8"},
 "T": {"tradeId":"df193874-a122-4695-9c9f-a321512a1f6d"},
 "R": {"id":"477c5b8e-0603-48fc-831f-7a72c52081da","runName":"93a0e45e-b7c3-43f6-b3cf-edc94de95457",
       "status":"0e278cda-bebd-4ec9-b9b8-22eccb81982f","message":"94f30f83-8a8e-4f51-bb08-d0b8a231865e",
       "startedBy":"05f990f3-3a40-48e6-a066-f57cc1182b18","startedOn":"d316b688-1b59-4b94-b1ca-bc8e117575c4",
       "updatedOn":"5a053825-881f-4692-ab15-ca58351007de"},
}
REL = {  # (source type, relationship name) -> (relationship uuid, target type)
 ("C","trade"): ("1507a3f2-0feb-4df3-80f8-7b1a28e192c7","T"),
 ("P","trade"): ("b043f244-ac93-4a94-b022-bf7e4b302e6c","T"),
}

def ref(tok):
    m = re.fullmatch(r"([A-Z])(?:>(\w+))?(?:\.(\w+))?", tok)
    if not m: sys.exit(f"bad token @{{{tok}}}")
    t, rel, fld = m.groups()
    uuid, name = RT[t]
    out = f"recordType!{{{uuid}}}{name}"
    ft = t
    if rel:
        ruuid, ft = REL[(t, rel)]
        out += f".relationships.{{{ruuid}}}{rel}"
    if fld:
        if fld not in F[ft]: sys.exit(f"unknown field @{{{tok}}}")
        out += f".fields.{{{F[ft][fld]}}}{fld}"
    return "'" + out + "'"

src = open(sys.argv[1]).read()
open(sys.argv[2], "w").write(re.sub(r"@\{([^}]+)\}", lambda m: ref(m.group(1)), src))
print("wrote", sys.argv[2])
