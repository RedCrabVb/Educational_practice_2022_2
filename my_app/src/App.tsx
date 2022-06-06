import './App.css';
import { Routes, Route, Link } from 'react-router-dom'

import { Home } from './pages/commons/HomePage'
import { NotePage } from './pages/NotePage'
import { Task } from './pages/TaskPage'
import { Notfoundpage } from './pages/commons/NotFoundPage'
import { LogIn } from './pages/commons/Login'

import { route } from "./utils/ScreenNames"
import { Registration } from './pages/commons/RegistrationPage';

function App() {
    return (
        <>
            <Routes>
                <Route path={route.home} element={<Home />}></Route>
                <Route path={route.login} element={<LogIn />}></Route>
                <Route path={route.registration} element={<Registration />}></Route>

                <Route path="*" element={<Notfoundpage />} />
            </Routes>
        </>
    )
}

export default App;
