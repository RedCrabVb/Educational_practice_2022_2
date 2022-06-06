import { useEffect, useState } from "react"
import { api } from '../utils/Api'
import { getItem } from '../utils/OperationItem'
import { ErrorView } from '../component/ErrorView'
import { TaskComponent } from '../component/TaskComponent'
import { Header } from "./commons/Header"
import { SMART_TASK } from "../utils/Storage"
import { styleBlockItem, styleContainerItem, styleItems } from './commons/css/item'
import { SmartTask } from "../component/class/SmartTask"

export const Task = () => {
    const [taskAll, setTaskAll] = useState<Array<SmartTask>>([])
    const [currentTask, setCurrentTask] = useState<number | undefined>(undefined)
    const [error, setError] = useState({ enable: false, text: '' })

    const [isLoadingItem, setIsLoading] = useState(false)


    function funcLoadItem() {
        getItem(setTaskAll, setError, api.smartTask, SMART_TASK)
    }

    useEffect(() => {
        if (!isLoadingItem) {
            setIsLoading(true)
            funcLoadItem()
        }
    })



    return (
        <>
            <Header />
            <ErrorView text={error.text} enable={error.enable} />
            <br></br>
            <div className="container" style={styleContainerItem}>
                <div className="row" >
                    <div className="col-2 m-1" style={styleBlockItem}>
                        <button style={{ height: '60px' }} className="btn btn-outline-primary mb-3 customButtons" onClick={() => { setCurrentTask(-1) }} >+ cоздать задачу</button>
                        <div style={styleItems}>
                            {
                                taskAll.reverse()
                                    .filter(t => t.completed == false)
                                    .sort(function(n1, n2){
                                        return new Date(n1.timeBound).getTime() - new Date(n2.timeBound).getTime(); 
                                      })
                                    .map(task => <TaskComponent
                                        setAllTask={setTaskAll}
                                        taskAll={taskAll}
                                        setCurrentTask={setCurrentTask} task={task} key={task.id} />)
                            }
                            {
                                taskAll.filter(t => t.completed == true).length != 0 &&
                                <>
                                    <p>Завершенные задания</p>
                                    {taskAll.filter(t => t.completed == true).map(task => <TaskComponent taskAll={taskAll} setAllTask={setTaskAll} setCurrentTask={setCurrentTask} task={task} key={task.id} />)}
                                </>
                            }

                        </div>

                    </div>
                    {/* <div className="col-6 m-1" style={{ width: '70%' }}>
                        {currentTask != undefined ? <TaskEdit idItem={currentTask} funcLoadItem={funcLoadItem} setCurrentTask={setCurrentTask} /> : <></>}
                    </div> */}
                </div>
            </div>
        </>
    )
}