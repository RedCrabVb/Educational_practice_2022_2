import CSS from 'csstype'
import { SetStateAction } from 'react';
import { api } from "../utils/Api"
import { saveItem } from '../utils/OperationItem'
import { SmartTask } from './class/SmartTask'

export const TaskComponent = ({ task, setCurrentTask, taskAll, setAllTask }:
    { task: SmartTask, setCurrentTask: (f: SetStateAction<undefined | number>) => void, taskAll: Array<SmartTask>, setAllTask: (f: Array<SmartTask>) => void }) => {

    const style: CSS.Properties = {
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        minHeight: '75px',
        display: 'inline-grid'
    }


    function chnageCheckBox(value: any) {
        task.completed = !task.completed
        let allTaskTmp = taskAll.filter(t => t.id != task.id)
        allTaskTmp.push(task)

        saveItem(task, (id: any) => { }, api.smartTask, () => {
            setAllTask(allTaskTmp)
        })
    }


    return (
        <>
            <div onClick={() => { setCurrentTask(task.id) }}
                className="btn btn-outline-secondary" style={style}>
                {task.specific}
                <br />
                {new Date(task.timeBound).toLocaleDateString()}
                <input className={"form-check-input"} type="checkbox" checked={task.completed} onChange={chnageCheckBox}></input>
            </div>
        </>
    )
};