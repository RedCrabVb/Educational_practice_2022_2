import { useEffect, useId, useState } from 'react'
import { USER } from "../../utils/Storage";
import { useNavigate } from "react-router-dom";
import { api } from '../../utils/Api'
import React from 'react'
import { Header } from './Header'

interface UserInfo {
    id: number,
    login: string,
    password: string,
    firstName: string,
    lastName: string,
    patronymic: string,
    mail: string,
    passport: string,
    amount: number,
    currency: string
}

interface HistoryActiveItem {
    lastActive: number | undefined
    useSessionId: string | undefined
    userAgent: string | undefined
    userId: number | undefined
}

export const Home = () => {
    const [authorized, isAuthorized] = useState(false)
    const [versionText, setVersion] = useState('')
    const [userInfo, setUserInfo] = useState<UserInfo | undefined>(undefined)
    const [historyActive, setHistoryActive] = useState<Array<HistoryActiveItem>>()

    const navigate = useNavigate()

    const requestOptions: RequestInit = {
        method: 'GET',
        headers: new Headers({
            'Content-Type': 'application/json'
        }),
        credentials: 'include',
    }

    function checkUser() {

        const userInfo = localStorage.getItem(USER)

        if (userInfo == null) {
            navigate("login", { replace: true })
        } else {
            console.log({ userInfo })
            isAuthorized(true)
            fetch(api.version, requestOptions)
                .then(d => { console.log({ fetchVersion: d }); return d.json() })
                .then(r => {
                    setVersion(r)
                })

            fetch(api.userInfo, requestOptions)            
                .then((response) => {
                    if (!response.ok) throw new Error(response.status.toString());
                    else return response.json();
                })
                .then((data) => {
                    console.log({body: data})
                    setUserInfo(data)
                })
                .catch((error) => {
                    console.log(error + " in registration")
                })

            fetch(api.userSession, requestOptions)//todo: fix
                .then((response) => {
                    if (!response.ok) throw new Error(response.status.toString());
                    else return response.json();
                })
                .then((data) => {
                    console.log({body: data})
                    setHistoryActive(data)
                })
                .catch((error) => {
                    console.log(error + " in get session")
                })
        }
    }

    useEffect(() => {
        if (!authorized) {
            checkUser()
        }
    }
    );

    function HistoryItem({item}: {item: HistoryActiveItem}): JSX.Element {
        return <div className='border border-1' style={{ margin: 10, padding: 10 }} >
            <p>??????????: {new Date(item.lastActive ? item.lastActive : 0).toLocaleDateString()}</p>
            <p>????????????????????: {item.userAgent}</p>
        </div>
    }


    return (
        <div>
            <Header />
            <div className={"container md-6 "} >
                <h1>Home</h1>
                {
                    userInfo ? <>
                        <p>??????????: {userInfo.mail}</p>
                        <p>??????????: {userInfo.login}</p>
                        <p>?????????? ??????????????: {userInfo.amount}</p>
                    </> : <></>
                }
                <br></br>
                <label>?????????????? ??????????????????</label>
                {
                    historyActive && historyActive.map(h => {return <HistoryItem  key={JSON.stringify(h).toString()} item={h} />} )
                }

                <p>api: v: {versionText}</p>
            </div>
        </div>
    )
}