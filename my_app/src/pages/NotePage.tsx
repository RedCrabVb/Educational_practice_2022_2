import React, { useEffect, useState } from "react"
import { api } from '../utils/Api'
import { getItem } from '../utils/OperationItem'
import { ErrorView } from '../component/ErrorView'
import { NoteComponent } from '../component/NoteComponent'
import { Header } from "./commons/Header"
import { NOTE } from "../utils/Storage"
import { styleBlockItem, styleContainerItem, styleItems} from './commons/css/item'
import { Note } from '../component/class/Note'

export const NotePage = () => {
    const [noteAll, setNoteAll] = useState<Array<Note>>([])
    const [currentNote, setCurrentNote] = useState<number | undefined>(undefined)
    const [error, setError] = useState({ enable: false, text: '' })

    const [isLoading, setIsLoading] = useState(false)

    useEffect(() => {
        if (!isLoading) {
            setIsLoading(true)
            getItem(setNoteAll, setError, api.note, NOTE)
            console.log(JSON.stringify(noteAll))
        }
    })

    function funcLoadItem() {
        getItem(setNoteAll, setError, api.note, NOTE)
    }


    return (
        <>
            <Header />
            <ErrorView text={error.text} enable={error.enable} />
            <br></br>
            <div className="container" style={styleContainerItem}>
                <div className="row" >
                    <div className="col-2 m-1" style={styleBlockItem}>
                        <button style={{height: '60px'}} className="btn btn-outline-primary mb-3 customButtons" onClick={() => { setCurrentNote(-1) }} >+ cоздать заметку</button>
                        <div style={styleItems}>
                            {
                                noteAll
                                .filter(t => t.pined == false)
                                .sort(function(n1, n2){
                                    return new Date(n1.lastEdit).getTime() - new Date(n2.lastEdit).getTime(); 
                                  })
                                .reverse()
                                .map(note => <NoteComponent note={note} setCurrentNote={setCurrentNote} key={note.id} noteAll={noteAll} setAllNote={setNoteAll} />)
                            }
                                                        {
                                noteAll.filter(t => t.pined == true).length != 0 &&
                                <>
                                    <p>Закрепленные заметки</p>
                                    {noteAll.filter(t => t.pined == true).map(note => <NoteComponent noteAll={noteAll} setAllNote={setNoteAll} setCurrentNote={setCurrentNote} note={note} key={note.id} />)}
                                </>
                            }

                        </div>

                    </div>
                    {/* <div className="col-6 m-1" style={{width: '70%'}}>
                        {currentNote != undefined ? <NoteEdit idItem={currentNote} funcLoadItem={funcLoadItem} setCurrentNote={setCurrentNote} /> : <></>}
                    </div> */}
                </div>
            </div>
        </>
    )
}