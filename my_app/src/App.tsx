import './App.css';
import { Routes, Route, Link } from 'react-router-dom'

import { Home } from './pages/commons/HomePage'
import { Notfoundpage } from './pages/commons/NotFoundPage'
import { LogIn } from './pages/commons/Login'

import { route } from "./utils/ScreenNames"
import { Registration } from './pages/commons/RegistrationPage';
import { FinacialProducts } from './pages/FinancialProducts';
import { Transactions } from './pages/Transactions';

function App() {
    return (
        <>
            <Routes>
                <Route path={route.home} element={<Home />}></Route>
                <Route path={route.login} element={<LogIn />}></Route>
                <Route path={route.registration} element={<Registration />}></Route>
                <Route path={route.finacialProducts} element={<FinacialProducts />}></Route>
                <Route path={route.transactions} element={<Transactions />}></Route>

                <Route path="*" element={<Notfoundpage />} />
            </Routes>
        </>
    )
}

export default App;
