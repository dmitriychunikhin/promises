CLEAR
SET PROCEDURE TO promises.prg

WITH CREATEOBJECT("SampleForm")
    .Show(1)
ENDWITH

DEFINE CLASS SampleForm AS Form
    Top = 0
    Left = 0
    Height = 700
    Width = 633
    DoCreate = .T.
    Caption = "Sample Form"
    Visible = .T.
    Name = "SampleForm1"
    
    promiseList1 = NULL
    promiseList2 = NULL
    ADD OBJECT fnList1 as Callable
    ADD OBJECT Then1 as Callable


    ADD OBJECT cmdFillList1 AS commandbutton WITH ;
        Top = 24, ;
        Left = 36, ;
        Height = 27, ;
        Width = 84, ;
        Caption = "Fill List1", ;
        Name = "cmdFillList1"

    ADD OBJECT cmdFillList2 AS commandbutton WITH ;
        Top = 24, ;
        Left = 150, ;
        Height = 27, ;
        Width = 84, ;
        Caption = "Fill List2", ;
        Name = "cmdFillList2"

    ADD OBJECT list1 AS listbox WITH ;
        Height = 252, ;
        Left = 36, ;
        Top = 96, ;
        Width = 552, ;
        Name = "List1"

    ADD OBJECT list2 AS listbox WITH ;
        Height = 252, ;
        Left = 36, ;
        Top = 400, ;
        Width = 552, ;
        Name = "List2"


    ADD OBJECT label1 AS label WITH ;
        Caption = "Label1", ;
        Height = 17, ;
        Left = 42, ;
        Top = 71, ;
        Width = 238, ;
        Name = "Label1"

    ADD OBJECT label2 AS label WITH ;
        Caption = "Label2", ;
        Height = 17, ;
        Left = 42, ;
        Top = 370, ;
        Width = 258, ;
        Name = "Label2"


    PROCEDURE cmdFillList1.Click
        Thisform.List1.Clear()
        Thisform.List1.ListIndex = 0
        Thisform.Label1.Refresh()
        
        Thisform.promiseList1 = AsyncRun(Thisform.fnList1, 150, "Hello, List1!")
        WITH Thisform.promiseList1.then(Thisform.Then1)
            WITH .then(Thisform.Then1)
                .then(Thisform.Then1)
            ENDWITH
            .then(Thisform.Then1)
        ENDWITH
    ENDPROC

    PROCEDURE cmdFillList2.Click
        Thisform.List2.Clear()
        Thisform.List2.ListIndex = 0
        Thisform.Label2.Refresh()

        Thisform.promiseList2 = AsyncRun("fnList2", Thisform, 150, "Hello, List2!")
        Thisform.promiseList2.then("Then2")
    ENDPROC

    PROCEDURE fnList1.call
        LPARAMETERS cntMax as Integer, msg as String
        Thisform.List1.AddItem(TRANSFORM(Thisform.List1.ListCount + 1))
        Thisform.Label1.Refresh()
        IF Thisform.List1.ListCount != m.cntMax
            RETURN AsyncRepeat(50)
        ENDIF
        RETURN m.msg
    ENDPROC

    PROCEDURE Then1.call
        LPARAMETERS msg
        m.msg = TRANSFORM(m.msg) + " then " + SYS(2015)
        Thisform.List1.AddItem(m.msg)
        m.Thisform.Label1.Refresh()
        RETURN m.msg
    ENDPROC


    PROCEDURE label1.Refresh
        This.Caption = TEXTMERGE("ListCount1 = <<Thisform.List1.ListCount>>")
    ENDPROC

    PROCEDURE label2.Refresh
        This.Caption = TEXTMERGE("ListCount2 = <<Thisform.List2.ListCount>>")
    ENDPROC

    PROCEDURE Destroy
        Thisform.promiseList1 = NULL
        Thisform.promiseList2 = NULL
    ENDPROC
ENDDEFINE


DEFINE CLASS fnList2 as Callable
    cnt = 0
    PROCEDURE call
        LPARAMETERS frm, cntMax as Integer, msg as String
        This.cnt = This.cnt + 1
        frm.List2.AddItem(TRANSFORM(This.cnt))
        frm.Label2.Refresh()
        IF This.cnt != m.cntMax
            RETURN AsyncRepeat(40)
        ENDIF
        m.res = CREATEOBJECT("empty")
        ADDPROPERTY(m.res, "frm", m.frm)
        ADDPROPERTY(m.res, "msg", m.msg)
        RETURN m.res
    ENDPROC
ENDDEFINE


DEFINE CLASS Then2 as Callable
    PROCEDURE call
        LPARAMETERS value
        m.value.msg = TRANSFORM(m.value.msg) + " then " + SYS(2015)
        m.value.frm.List2.AddItem(m.value.msg)
        m.value.frm.Label2.Refresh()
        RETURN m.value
    ENDPROC
ENDDEFINE
