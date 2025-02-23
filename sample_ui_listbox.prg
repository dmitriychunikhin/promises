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


    ADD OBJECT interval1 AS IntervalCallable
    ADD OBJECT interval2 AS IntervalCallable
    ADD OBJECT then1 AS Callable
    ADD OBJECT then2 AS Callable


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

        WITH Thisform.Interval1
            .AddProperty("cnt", 0)
            .AddProperty("promise", Promise())
            WITH .promise
                WITH .then(Thisform.Then1)
                    WITH .then(Thisform.Then1)
                        .then(Thisform.Then1)
                    ENDWITH
                ENDWITH
                .then(Thisform.Then1)
            ENDWITH
        ENDWITH
        Thisform.Interval1.ClearInterval()
        Thisform.Interval1.SetInterval(100, 150, "Hello, Interval1!")
    ENDPROC

    PROCEDURE cmdFillList2.Click
        Thisform.List2.Clear()
        Thisform.List2.ListIndex = 0
        Thisform.Label2.Refresh()

        WITH Thisform.Interval2
            .AddProperty("cnt", 0)
            .AddProperty("promise", Promise())
            .promise.then(Thisform.Then2)
        ENDWITH
        Thisform.Interval2.ClearInterval()
        Thisform.Interval2.SetInterval(100, 150, "Hello, Interval2!")
    ENDPROC

    PROCEDURE Interval1.call
        LPARAMETERS cntMax as Integer, msg as String

        This.cnt = This.cnt + 1
        Thisform.List1.AddItem(TRANSFORM(This.cnt))
        Thisform.Label1.Refresh()
        IF This.cnt = m.cntMax
            This.promise.resolve(m.msg)
            This.ClearInterval()
        ENDIF
    ENDPROC

    PROCEDURE Interval2.call
        LPARAMETERS cntMax as Integer, msg as String

        This.cnt = This.cnt + 1
        Thisform.List2.AddItem(TRANSFORM(This.cnt))
        Thisform.Label2.Refresh()
        IF This.cnt = m.cntMax
            This.promise.resolve(m.msg)
            This.ClearInterval()
        ENDIF
    ENDPROC

    PROCEDURE then1.call
        LPARAMETERS value
        LOCAL res
        m.res = TRANSFORM(m.value) + " then " + SYS(2015)
        Thisform.List1.AddItem(m.res)
        Thisform.Label1.Refresh()
        RETURN m.res
    ENDPROC

    PROCEDURE then2.call
        LPARAMETERS value
        LOCAL res
        m.res = TRANSFORM(m.value) + " then " + SYS(2015)
        Thisform.List2.AddItem(m.res)
        Thisform.Label2.Refresh()
        RETURN m.res
    ENDPROC


    PROCEDURE label1.Refresh
        This.Caption = TEXTMERGE("ListCount1 = <<Thisform.List1.ListCount>>")
    ENDPROC

    PROCEDURE label2.Refresh
        This.Caption = TEXTMERGE("ListCount2 = <<Thisform.List2.ListCount>>")
    ENDPROC

    PROCEDURE Destroy
        Thisform.Interval1.ClearInterval()
        Thisform.Interval1.AddProperty("promise", NULL)

        Thisform.Interval2.ClearInterval()
        Thisform.Interval2.AddProperty("promise", NULL)
    ENDPROC
ENDDEFINE
