import React from 'react'

export const ErrorView = ({text, enable = false}: {text: string, enable: boolean}) => {

    if (enable) {
        return (
            <div className="containerError">
                <p>Error: {text}</p>
            </div>
        )
    } else {
        return (<div></div>)
    }
}
