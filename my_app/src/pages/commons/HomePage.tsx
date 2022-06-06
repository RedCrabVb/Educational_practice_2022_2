import { useEffect, useId, useState } from 'react'
import { USER } from "../../utils/Storage";
import { useNavigate } from "react-router-dom";
import { api } from '../../utils/Api'
import React from 'react'
import { Header } from './Header'

interface UserInfo {
    email: string;
    username: string;
    chatIdTg: string | null;
    confirmedTg: boolean;
    secretTokenTg: string | null;
}

export const Home = () => {
    const [authorized, isAuthorized] = useState(false)
    const [versionText, setVersion] = useState('')
    const [userInfo, setUserInfo] = useState<UserInfo | undefined>(undefined)

    const navigate = useNavigate()

    const requestOptions: RequestInit = {
        method: 'GET',
        headers: new Headers({ }),
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
                .then(d => { console.log({fetchVersion: d}); return d.json() })
                .then(r => {
                    setVersion(r)
                })

        }
    }

    useEffect(() => {
        if (!authorized) {
            checkUser()
        }
    }
    );

    function historyItem(str: string): JSX.Element {
        return <div style={{margin: 10}} >
            <span>{str}</span>
        </div>
    }


    return (
        <div>
            <Header />
            <div className={"container md-6"} >
                <h1>Home</h1>
                {
                    userInfo ? <>
                        <p>Почта: {userInfo.email}</p>
                        <p>Логин: {userInfo.username}</p>
                        {userInfo.secretTokenTg != null && !userInfo.confirmedTg ?
                            <p>Код для подписки бота: {userInfo.secretTokenTg}</p>
                            : <></>
                        }

                        <p>Оповещения в телеграмме {!userInfo.confirmedTg ? <span>не</span> : <></>} активированы</p>
                    </> : <></>
                }
                <br></br>
                <label>История посещений</label>
                {historyItem("2002 info")}
                {historyItem("2003 info yandex")}
                {historyItem("2004 info honor 10")}

                <p>api: v: {versionText}</p>
            </div>
        </div>
    )
}