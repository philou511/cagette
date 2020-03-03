import React from 'react'

export class Hello extends React.Component {
    render() {
        return (
            <div>
                Hello
            </div>
        )
    }
}


export const HelloF = () => {
    return <div>HelloF</div>
}

export const HelloFC: React.FC = () => {
    return <div>HelloFC</div>
}