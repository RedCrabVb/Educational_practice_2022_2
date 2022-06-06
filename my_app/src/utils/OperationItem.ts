import {NOTE, USER} from "./Storage";
import { Item } from "../component/class/Item";
import { Dispatch, SetStateAction } from "react";


export function getItem<E extends Item>(setItem: Dispatch<SetStateAction<E[]>>, setError: (f: {enable: boolean, text: string}) => void, api: string, local: string) {
    const data: string = localStorage.getItem(USER) || 'null'
    
    const requestOptions = {
        method: 'GET',
        headers: new Headers(
            { 
                'Content-Type': 'application/json', 
                'Authorization': data.toString()
            }
        ),
    }
    fetch(api, requestOptions)
        .then((response) => {
            if (!response.ok) throw new Error(response.status.toString());
            else return response.json();
        })
        .then((data) => {
            console.log(data)
            setItem(data)
            localStorage.setItem(local, JSON.stringify(data))
           
        }).catch(error => {
            console.log({error})

            if (error.message === 'Network request failed') {
                // AsyncStorage.getItem(NOTE).then(data => {
                //     console.log("Okey, load item from memory")
                //     console.log(data)
                //     setItem(JSON.parse(data))
                // })
            } else {
                setError({enable: true, text: error.message})
            }
    })

}

export function deleteItem(id: number, api: string, afterDelete = () => {}) {
    console.log(`ip = ${id} api = ${api}`)
    const data: string = localStorage.getItem(USER) || 'null'
    
    if (id != -1) {
        const requestOptions = {
            method: 'DELETE',
            headers: new Headers(
                { 
                    'Content-Type': 'application/json', 
                    'Authorization': data.toString()
                }
            ),
        }
        fetch(api + `/${id}`, requestOptions)
            .then((data) => {
                afterDelete()
            })
            .catch((error) => alert(error))
    } else {
        afterDelete()
    }
}


export function saveItem(item: any, changeID: (id: number) => void, api: string, afterUpdate = () => {}) {
    const data: string = localStorage.getItem(USER) || 'null'
    
    const requestOptions = {
        method: 'POST',
        headers: new Headers(
            { 
                'Content-Type': 'application/json', 
                'Authorization': data.toString()
            }
        ),
        body: JSON.stringify(item).toString()
    }
    fetch(api, requestOptions)
        .then((response) => {
            if (!response.ok) throw new Error(response.status.toString())
            else return response.json()
        })
        .then((data) => {
            changeID(data.id)
            afterUpdate()
        })
        .catch((error) => { alert(error) })
}