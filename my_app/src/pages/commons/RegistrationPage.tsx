import React, { useEffect, useState } from 'react'
import { USER } from '../../utils/Storage'
import { api } from '../../utils/Api'
import { useNavigate } from "react-router-dom"
import { ErrorView } from '../../component/ErrorView'
import { route } from "../../utils/ScreenNames"
import { User } from '../../component/class/User'

export const Registration = () => {
    const [password, setPassword] = useState("")
    const [password2, setPassword2] = useState("")
    const [mail, setMail] = useState("")
    const [phone, setPhone] = useState("")
    const [pasport, setPassport] = useState("")
    const [firstName, setFirstName] = useState("")
    const [lastName, setLastName] = useState("")
    const [patronymic, setPatronymic] = useState("")

    const [login, setLogin] = useState<string | undefined>(undefined)

    const [errors, setErrors] = React.useState({
        login: undefined,
        mail: undefined,
        password: undefined,
        password2: undefined
    })
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
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ password, firstName, lastName, patronymic, mail, pasport }).toString()
        };

        console.log(JSON.stringify({ password, firstName, lastName, patronymic, mail, pasport }).toString())
        fetch(api.registration, requestOptions)
            .then((response) => {
                if (!response.ok) throw new Error(response.status.toString());
                else return response.json();
            })
            .then((data) => {
                console.log(data)
                setLogin(data.login)
            })
            .catch((error) => {
                console.log(error + " in registration")
                setError({ enable: true, text: 'Попробуйте ввести другой логин или повторить попытку регистрации позднее' })
            })
    }

    function ErrorSpan({ text }: { text: string | undefined }) {
        return (
            text != undefined ? <span className="containerError mb-3">{text}</span> : <br></br>
        )
    }


    function elementInput(value: string, setValue: (f: string) => void, name: string, error_text: string | undefined, type: string = 'text') {
        return (
            <>
                <div className="mb-2">
                    <ErrorSpan text={error_text} />
                    <label className="form-label">{name}</label>
                    <input type={type} className="form-control"
                        value={value} onChange={(e) => setValue(e.target.value)} />
                </div>
            </>
        )
    }


    return (
        <div className="cotainer">

            <div className="containerForm border">
                <div className="col-md-6" >
                    <ErrorView text={error.text} enable={error.enable} />
                    {elementInput(firstName, setFirstName, 'Имя', errors.login)}
                    {elementInput(lastName, setLastName, 'Фамилия', errors.login)}
                    {elementInput(patronymic, setPatronymic, 'Отчество', errors.login)}
                    {elementInput(phone, setPhone, 'Телефон', errors.login)}
                    {elementInput(pasport, setPassport, 'Паспорт', errors.login)}
                    {elementInput(mail, setMail, 'Почта', errors.mail)}
                    {elementInput(password, setPassword, 'Пароль', errors.password, 'password')}
                    {elementInput(password2, setPassword2, 'Пароль ещё раз', errors.password2, 'password')}

                    <div className="mb-2">
                        <button onClick={validate} className="btn btn-primary mb-3 customButtons">Регистрация</button>
                    </div>


                    {login && <><span>Ваш логин: {login}</span>
                        <div className="mb-2">
                            <button onClick={() => { navigate(route.home, { replace: true }) }} className="btn btn-primary mb-3 customButtons">Пройти авторизацию</button>
                        </div></>}
                </div>
            </div>
        </div>
    )

}