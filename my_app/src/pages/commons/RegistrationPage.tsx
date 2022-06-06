import React, { useEffect, useState } from 'react'
import { USER } from '../../utils/Storage'
import { api } from '../../utils/Api'
import { useNavigate } from "react-router-dom"
import { ErrorView } from '../../component/ErrorView'
import { route } from "../../utils/ScreenNames"

export const Registration = () => {
    const [password, setPassword] = useState("")
    const [password2, setPassword2] = useState("")
    const [mail, setMail] = useState("")
    const [login, setLogin] = useState("")

    const [errors, setErrors] = React.useState({login: undefined, mail: undefined, password: undefined, password2: undefined})
    const [error, setError] = React.useState({ enable: false, text: '' })

    const navigate = useNavigate()

    const validate = async () => {
        let isValid = true

        function check(check: boolean, text: string, field: string) {
            if (check) {
                handleError(text, field)
                isValid = false
            } else {
                handleError(undefined, field)
            }
        }

        check(mail.length < 4, 'Почта должна быть длиннее 4 символов', 'email')
        check(login.length < 4, 'Логин должен быть длиннее 4 символов', 'login')
        check(password != password2, 'Пароли должны быть одинаковы', 'password2')
        check(password.length < 4, 'Пароль должен быть длиннее 4 символов', 'password')

        if (isValid) {
            handlerAut()
        }
    }

    const handleError = (error: string | undefined, input: string) => {
        setErrors(prevState => ({ ...prevState, [input]: error }));
    }

    const handlerAut = () => {
        const requestOptions = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: `login=${login}&email=${mail}&password=${password}`
        };
        fetch(api.registration, requestOptions)
            .then((response) => {
                if (!response.ok) throw new Error(response.status.toString());
                else return response;
            })
            .then((data) => {
                console.log(data)
                localStorage.setItem(USER, 'Basic ' + window.btoa(login + ":" + password))
                navigate(route.home, { replace: true })
            })
            .catch((error) => {
                console.log(error + " in registration")
                setError({ enable: true, text: 'Попробуйте ввести другой логин или повторить попытку регистрации позднее' })
            })
    }

    function ErrorSpan({ text }: {text: string | undefined }) {
        return (
            text != undefined ? <span className="containerError mb-3">{text}</span> : <br></br>
        )
    }


    function elementInput(value: string, setValue: (f: string) => void, name: string, error_text: string | undefined) {
        return (
            <>
                <div className="mb-2">
                    <ErrorSpan text={error_text} />
                    <label className="form-label">{name}</label>
                    <input type="text" className="form-control"
                        value={value} onChange={(e) => setValue(e.target.value)} />
                </div>
            </>
        )
    }


    return (
        <div className="containerForm col-md-6">

            <div className="col-md-6">
                <ErrorView text={error.text} enable={error.enable}/>
                {elementInput(login, setLogin, 'Имя пользователя', errors.login)}
                {elementInput(mail, setMail, 'Почта', errors.mail)}
                {elementInput(password, setPassword, 'Пароль', errors.password)}
                {elementInput(password2, setPassword2, 'Пароль ещё раз', errors.password2)}

                <div className="mb-2">
                    <button onClick={validate} className="btn btn-primary mb-3 customButtons">Регистрация</button>
                </div>
            </div>

        </div>
    )

}